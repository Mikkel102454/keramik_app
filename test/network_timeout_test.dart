import 'dart:async';
import 'dart:io';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/repositories/account_repository.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/entitlement_repository.dart';
import 'package:ceramic_app/ui/pages/login/login_page.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page_controller.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page.dart';
import 'package:ceramic_app/ui/pages/profile/profile_edit_controller.dart';
import 'package:ceramic_app/utils/network_timeout.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_delivery_test.dart' as delivery;
import 'chat_media_flow_test.dart' as media;
import 'profile_edit_test.dart' as profile;
import 'unified_messaging_test.dart' as messaging;

class FailureAdapter implements HttpClientAdapter {
  FailureAdapter(this.type);
  final DioExceptionType type;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    throw DioException(requestOptions: options, type: type);
  }

  @override
  void close({bool force = false}) {}
}

class InterruptedUploadAdapter extends delivery.DeliveryAdapter {
  bool interrupt = true;
  final attempts = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/attachments')) {
      attempts.add(
        (options.data as FormData).fields
            .firstWhere((field) => field.key == 'clientMessageId')
            .value,
      );
      if (interrupt) {
        interrupt = false;
        // Consume part of the multipart body before the connection stalls.
        await requestStream?.first;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.sendTimeout,
        );
      }
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late int expired;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final testUri = Uri.parse('http://127.0.0.1/api/account/me');

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bounded-network-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    await ApiClient.init();
    // Doubles reject every request; real transport tests replace this with
    // an ephemeral loopback server. Never use the configured backend URL.
    ApiClient.dio.options.baseUrl = 'http://127.0.0.1';
    ApiClient.dio.httpClientAdapter = FailureAdapter(
      DioExceptionType.receiveTimeout,
    );
    expired = 0;
    ApiClient.onUnauthorized = () => expired++;
    await ApiClient.cookieJar.saveFromResponse(testUri, [
      Cookie('test-session', 'retained'),
    ]);
  });
  tearDown(() async {
    ApiClient.dio.close(force: true);
    ApiClient.onUnauthorized = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  Future<void> expectSessionRetained() async {
    expect(expired, 0);
    expect(
      (await ApiClient.cookieJar.loadForRequest(testUri)).single.value,
      'retained',
    );
  }

  Future<HttpServer> localServer() async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previous);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    ApiClient.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
    ApiClient.dio.httpClientAdapter = IOHttpClientAdapter();
    ApiClient.dio.options
      ..connectTimeout = const Duration(milliseconds: 150)
      ..sendTimeout = const Duration(milliseconds: 150)
      ..receiveTimeout = const Duration(milliseconds: 150);
    return server;
  }

  test(
    'defaults and intentional per-request finite overrides are preserved',
    () async {
      expect(ApiClient.dio.options.connectTimeout, const Duration(seconds: 10));
      expect(ApiClient.dio.options.sendTimeout, const Duration(seconds: 30));
      expect(ApiClient.dio.options.receiveTimeout, const Duration(seconds: 30));
      final adapter = FailureAdapter(DioExceptionType.receiveTimeout);
      ApiClient.dio.httpClientAdapter = adapter;
      await expectLater(
        EntitlementRepository.load(),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.single.sendTimeout, const Duration(seconds: 15));
      expect(
        adapter.requests.single.receiveTimeout,
        const Duration(seconds: 15),
      );
      final target = File('${directory.path}/attachment');
      await expectLater(
        ChatRepository.downloadAttachment(
          'chat',
          'message',
          target,
          CancelToken(),
        ),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.last.receiveTimeout, const Duration(seconds: 30));
      expect(await target.exists(), isFalse);
      await expectLater(
        AccountRepository.downloadExport('isolated'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.last.responseType, ResponseType.stream);
      expect(adapter.requests.last.receiveTimeout, const Duration(seconds: 30));
      expect(
        await File('${directory.path}/keramik-data-isolated.zip').exists(),
        isFalse,
      );
      await expectSessionRetained();
    },
  );

  for (final bodyStall in [false, true]) {
    test(
      'real IO delayed ${bodyStall ? 'body' : 'headers'} reaches receive timeout',
      () async {
        final server = await localServer();
        var requests = 0;
        server.listen((request) async {
          requests++;
          if (bodyStall) {
            request.response.bufferOutput = false;
            request.response.headers.contentType = ContentType.binary;
            request.response.write('first chunk');
            await request.response.flush();
          }
          // Leave the response open until isolated server teardown.
        });
        await expectLater(
          ApiClient.dio.get('/delay'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.receiveTimeout,
            ),
          ),
        );
        expect(requests, 1);
        await expectSessionRetained();
      },
    );
  }

  test('receive limit is inactivity, not total download duration', () async {
    final server = await localServer();
    ApiClient.dio.options.receiveTimeout = const Duration(milliseconds: 500);
    server.listen((request) async {
      try {
        for (var i = 0; i < 5; i++) {
          request.response.write('chunk');
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
        await request.response.close();
      } catch (_) {
        /* Isolated client/server teardown. */
      }
    });
    final response = await ApiClient.dio.get<String>('/flow');
    expect(response.data, 'chunk' * 5);
  });

  test('real IO stalled upload reaches send timeout without retry', () async {
    final server = await localServer();
    server.listen((request) {
      request.listen((_) {}, onError: (_) {});
    });
    Stream<Uint8List> upload() async* {
      yield Uint8List.fromList([1]);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      yield Uint8List.fromList([2]);
    }

    await expectLater(
      ApiClient.dio.post(
        '/upload',
        data: upload(),
        options: Options(headers: {Headers.contentLengthHeader: 2}),
      ),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.sendTimeout,
        ),
      ),
    );
    await expectSessionRetained();
  });

  test(
    'real IO refused local connection is bounded and preserves session',
    () async {
      final server = await localServer();
      await server.close(force: true);
      // Windows may spend about a second reporting a refused TCP connection.
      ApiClient.dio.options.connectTimeout = const Duration(seconds: 3);
      await expectLater(
        ApiClient.dio.get('/refused'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
      await expectSessionRetained();
    },
  );

  test('IO stalled connection factory reaches connection timeout', () async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previous);
    ApiClient.dio.options.connectTimeout = const Duration(milliseconds: 100);
    ApiClient.dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () =>
          HttpClient()
            ..connectionFactory = (_, _, _) async =>
                ConnectionTask.fromSocket(Completer<Socket>().future, () {}),
    );
    await expectLater(
      ApiClient.dio.get('/stalled-connect'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionTimeout,
        ),
      ),
    );
    await expectSessionRetained();
  });

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ]) {
    test(
      '$type startup auth check leaves cookies and retry available',
      () async {
        ApiClient.dio.httpClientAdapter = FailureAdapter(type);
        final cubit = AuthenticationCubit();
        addTearDown(cubit.close);
        await cubit.checkAuthStatus();
        expect(
          cubit.state,
          AuthenticationState.error(
            type == DioExceptionType.connectionError
                ? 'Network error'
                : AuthenticationCubit.requestTimedOutMessage,
          ),
        );
        await expectSessionRetained();
      },
    );
    test(
      '$type auth check and logout never discard an existing session',
      () async {
        final cubit = AuthenticationCubit();
        addTearDown(cubit.close);
        final success = messaging.MessagingAdapter();
        // Seed authentication through a successful login response.
        ApiClient.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.extra['loginSuccess'] == true) {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {'success': true, 'data': {}},
                  ),
                );
              } else {
                handler.next(options);
              }
            },
          ),
        );
        ApiClient.dio.options.extra['loginSuccess'] = true;
        ApiClient.dio.httpClientAdapter = success;
        cubit.identifierChanged('potter');
        cubit.passwordChanged('synthetic');
        await cubit.login();
        expect(cubit.state, const AuthenticationState.authenticated());
        ApiClient.dio.options.extra.clear();
        ApiClient.dio.httpClientAdapter = FailureAdapter(type);
        await cubit.checkAuthStatus();
        expect(cubit.state, const AuthenticationState.authenticated());
        await expectLater(cubit.logout(), throwsA(isA<DioException>()));
        expect(cubit.state, const AuthenticationState.authenticated());
        await expectSessionRetained();
      },
    );
  }

  test(
    'lost committed text response recovers only on explicit retry with the same ID',
    () async {
      final adapter = messaging.MessagingAdapter()
        ..stored = messaging.conversationJson(status: 'ACTIVE')
        ..loseNextResponse = true;
      ApiClient.dio.httpClientAdapter = adapter;
      final controller = ConversationPageController(
        DirectConversationDto.fromJson(adapter.stored!),
      );
      addTearDown(controller.dispose);
      expect(await controller.send('retained draft'), isFalse);
      expect(controller.isSending, isFalse);
      final pending = controller.localSends.single;
      expect(pending.message.body, 'retained draft');
      expect(pending.unconfirmed, isTrue);
      expect(adapter.sendIds, hasLength(1));
      expect(
        adapter.messages,
        hasLength(1),
      ); // Server committed before timing out.
      await controller.retryLocalSend(pending);
      expect(adapter.sendIds.toSet(), hasLength(1));
      expect(adapter.messages, hasLength(1));
      expect(controller.localSends, isEmpty);
      await expectSessionRetained();
    },
  );

  testWidgets(
    'voice timeout restores preview and keeps the recording retry ID',
    (tester) async {
      final harness = media.VoiceHarness();
      addTearDown(harness.controller.dispose);
      harness.uploadGate = Completer<ChatMessageDto>();
      await harness.controller.start();
      harness.advance();
      final send = harness.controller.release();
      await tester.pump();
      harness.uploadGate!.completeError(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.sendTimeout,
        ),
      );
      await send;
      expect(harness.controller.sendTimedOut, isTrue);
      expect(harness.controller.file, isNotNull);
      expect(harness.deleted, isEmpty);
      expect(harness.ids, hasLength(1));
      harness.uploadGate = null;
      await harness.controller.send();
      expect(harness.ids, hasLength(2));
      expect(harness.ids.toSet(), hasLength(1));
      expect(harness.controller.sendTimedOut, isFalse);
      expect(harness.deleted, hasLength(1));
    },
  );

  test(
    'timed-out history refresh recovers loading and retains displayed messages',
    () async {
      final adapter = messaging.MessagingAdapter()
        ..stored = messaging.conversationJson(status: 'ACTIVE');
      adapter.messages.add(adapter.message('existing message', 1));
      ApiClient.dio.httpClientAdapter = adapter;
      final controller = ConversationPageController(
        DirectConversationDto.fromJson(adapter.stored!),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.messages.single.body, 'existing message');
      ApiClient.dio.httpClientAdapter = FailureAdapter(
        DioExceptionType.receiveTimeout,
      );
      await controller.load();
      expect(controller.isLoading, isFalse);
      expect(controller.messages.single.body, 'existing message');
      await expectSessionRetained();
    },
  );

  for (final type in ['IMAGE', 'VOICE']) {
    test(
      'interrupted $type upload keeps file and UUID until explicit retry succeeds',
      () async {
        final adapter = InterruptedUploadAdapter()
          ..stored = messaging.conversationJson(status: 'ACTIVE');
        ApiClient.dio.httpClientAdapter = adapter;
        final file = await File(
          '${directory.path}/draft',
        ).writeAsBytes([1, 2, 3]);
        final controller = ConversationPageController(
          DirectConversationDto.fromJson(adapter.stored!),
        );
        addTearDown(controller.dispose);
        await expectLater(
          controller.sendAttachment(
            file,
            'stable-retry-id',
            ChatAttachmentDto(type: type, size: 3),
            ownsFile: true,
          ),
          throwsA(isA<DioException>()),
        );
        expect(controller.isSending, isFalse);
        expect(controller.localSends.single.inFlight, isFalse);
        expect(controller.localSends.single.unconfirmed, isTrue);
        expect(await file.exists(), isTrue);
        expect(adapter.attempts, ['stable-retry-id']);
        await controller.retryLocalSend(controller.localSends.single);
        expect(adapter.attempts, ['stable-retry-id', 'stable-retry-id']);
        expect(controller.messages, hasLength(1));
        expect(await file.exists(), isFalse);
        await expectSessionRetained();
      },
    );
  }

  test(
    'timed-out profile save preserves entered names and recovers loading state',
    () async {
      final controller = ProfileEditController(profile.account);
      addTearDown(controller.dispose);
      controller.changeNames(forename: 'Draft name');
      expect(await controller.save(), isNull);
      expect(controller.forename, 'Draft name');
      expect(controller.saving, isFalse);
      expect(controller.saveTimedOut, isTrue);
      expect(controller.canSave, isTrue);
      expect(
        (ApiClient.dio.httpClientAdapter as FailureAdapter).requests,
        hasLength(1),
      );
      await expectSessionRetained();
    },
  );

  for (final language in ['en', 'da']) {
    messaging.messagingWidgetTest(
      'timed-out chat send is localized as unconfirmed in $language',
      (tester) async {
        final adapter = messaging.MessagingAdapter()
          ..stored = messaging.conversationJson(status: 'ACTIVE');
        ApiClient.dio.httpClientAdapter = adapter;
        final conversation = DirectConversationDto.fromJson(adapter.stored!);
        final controller = ConversationPageController(conversation);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ConversationPage(
              initialConversation: conversation,
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();
        adapter.loseNextResponse = true;
        await tester.runAsync(() => controller.send('uncertain draft'));
        await tester.pumpAndSettle();
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        expect(find.text(l10n.requestOutcomeUnconfirmed), findsOneWidget);
        expect(find.text(l10n.requestTimedOut), findsOneWidget);
        expect(find.text(l10n.chatMessageNotSent), findsNothing);
        expect(adapter.sendIds, hasLength(1));
      },
    );
    testWidgets(
      'login timeout feedback, draft and retry remain available in $language',
      (tester) async {
        final cubit = AuthenticationCubit();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const LoginPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'draft potter');
        await tester.enterText(fields.at(1), 'synthetic password');
        await tester.runAsync(cubit.login);
        await tester.pumpAndSettle();
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        expect(find.text(l10n.requestTimedOut), findsOneWidget);
        expect(
          tester.widget<TextField>(fields.at(0)).controller!.text,
          'draft potter',
        );
        expect(
          tester.widget<TextField>(fields.at(1)).controller!.text,
          'synthetic password',
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.runAsync(cubit.login);
        expect(
          (ApiClient.dio.httpClientAdapter as FailureAdapter).requests,
          hasLength(2),
        );
        await tester.runAsync(expectSessionRetained);
        expect(
          l10n.requestFailure(
            DioException(
              requestOptions: RequestOptions(),
              type: DioExceptionType.receiveTimeout,
            ),
            'fallback',
          ),
          l10n.requestTimedOut,
        );
        expect(l10n.requestFailure(StateError('test'), 'fallback'), 'fallback');
        expect(
          isNetworkTimeout(
            DioException(
              requestOptions: RequestOptions(),
              type: DioExceptionType.connectionError,
            ),
          ),
          isFalse,
        );
      },
    );
  }
}
