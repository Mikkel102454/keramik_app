import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/app/chat_voice_draft_controller.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'unified_messaging_test.dart' as messaging;
import 'chat_media_flow_test.dart' as media;

class DeliveryAdapter extends messaging.MessagingAdapter {
  Completer<void>? gate;
  bool failNext = false;
  bool failHistory = false;
  final List<String> mediaIds = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final outgoing =
        options.method == 'POST' &&
        (options.path.endsWith('/messages') ||
            options.path.endsWith('/attachments') ||
            options.path.endsWith('/ceramics'));
    if (!outgoing) {
      if (failHistory &&
          options.method == 'GET' &&
          options.path.endsWith('/messages')) {
        return response(null, success: false);
      }
      return super.fetch(options, requestStream, cancelFuture);
    }
    if (options.data is FormData) {
      mediaIds.add(
        (options.data as FormData).fields
            .firstWhere((field) => field.key == 'clientMessageId')
            .value,
      );
    }
    await requestStream?.drain<void>();
    await gate?.future;
    if (failNext) {
      failNext = false;
      return response(null, success: false);
    }
    if (options.path.endsWith('/messages')) {
      return super.fetch(options, requestStream, cancelFuture);
    }
    final type = options.data is FormData
        ? (options.data as FormData).fields
              .firstWhere((field) => field.key == 'type')
              .value
        : 'CERAMIC';
    final receipt = {
      ...message('', messages.length + 1),
      'type': type,
      if (type != 'CERAMIC')
        'attachment': {
          'type': type,
          'size': 4,
          if (type == 'IMAGE') ...{'width': 100, 'height': 300},
          if (type == 'VOICE') 'durationMs': 5000,
        },
      if (type == 'CERAMIC') 'ceramic': {'available': true, 'title': 'Cup'},
    };
    messages.add(receipt);
    return response(receipt);
  }
}

void main() {
  late DeliveryAdapter adapter;
  setUp(() {
    adapter = DeliveryAdapter()
      ..stored = messaging.conversationJson(status: 'ACTIVE');
    ApiClient.dio = Dio(
      BaseOptions(
        baseUrl: 'https://isolated.test',
        validateStatus: (_) => true,
      ),
    )..httpClientAdapter = adapter;
  });
  tearDown(() => ApiClient.dio.close(force: true));

  for (final locale in ['en', 'da']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      messaging.messagingWidgetTest(
        '$locale $brightness optimistic send, failure and row retry',
        (tester) async {
          tester.view.physicalSize = const Size(320, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final conversation = DirectConversationDto.fromJson(adapter.stored!);
          final controller = ConversationPageController(conversation);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              theme: ThemeData(brightness: brightness),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.6),
                  viewInsets: const EdgeInsets.only(bottom: 220),
                ),
                child: child!,
              ),
              home: ConversationPage(
                initialConversation: conversation,
                controller: controller,
              ),
            ),
          );
          await tester.pumpAndSettle();
          adapter.gate = Completer<void>();
          adapter.failNext = true;
          await tester.enterText(find.byType(TextField), 'Hello 🌸');
          await tester.pump();
          await tester.tap(find.byIcon(Icons.send));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
          expect(controller.localSends, hasLength(1));
          final pending = controller.localSends.single;
          expect(
            find.byKey(ValueKey('chat-row-${pending.message.id}')),
            findsOneWidget,
          );
          expect(
            find.text(locale == 'en' ? 'Sending…' : 'Sender…'),
            findsOneWidget,
          );
          expect(controller.messages, isEmpty);
          expect(adapter.messages, isEmpty);
          expect(tester.takeException(), isNull);
          adapter.gate!.complete();
          await tester.pumpAndSettle();
          expect(
            find.text(locale == 'en' ? 'Not sent' : 'Ikke sendt'),
            findsOneWidget,
          );
          final field = tester.widget<TextField>(find.byType(TextField));
          expect(field.controller!.text, 'Hello 🌸');
          expect(controller.localSends.single, same(pending));
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(ValueKey('retry-${pending.clientId}')));
          await tester.pumpAndSettle();
          expect(controller.localSends, isEmpty);
          expect(controller.messages, hasLength(1));
          expect(adapter.sendIds.single, pending.clientId);
          expect(field.controller!.text, isEmpty);
          expect(
            find.text(locale == 'en' ? 'Not sent' : 'Ikke sendt'),
            findsNothing,
          );
          expect(
            adapter.requests
                .where((r) => r.path.endsWith('/read'))
                .every(
                  (r) => !(r.data as Map)['messageId'].toString().startsWith(
                    'local-',
                  ),
                ),
            isTrue,
          );
        },
      );
    }
  }

  for (final type in ['IMAGE', 'VOICE']) {
    test(
      '$type optimistic upload retains file and UUID, acknowledgement replaces preview',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'chat-delivery-',
        );
        final file = await File(
          '${directory.path}/draft.bin',
        ).writeAsBytes([1, 2, 3, 4]);
        final controller = ConversationPageController(
          DirectConversationDto.fromJson(adapter.stored!),
        );
        try {
          adapter.gate = Completer<void>();
          adapter.failNext = true;
          const clientId = '50000000-0000-4000-8000-000000000001';
          final upload = controller.sendAttachment(
            file,
            clientId,
            ChatAttachmentDto(
              type: type,
              size: 4,
              width: 100,
              height: 300,
              durationMs: 5000,
            ),
            ownsFile: true,
          );
          final failure = expectLater(upload, throwsException);
          expect(controller.localSends.single.message.type, type);
          expect(controller.messages, isEmpty);
          expect(await file.exists(), isTrue);
          adapter.gate!.complete();
          await failure;
          final pending = controller.localSends.single;
          expect(pending.failed, isTrue);
          expect(await file.exists(), isTrue);
          await controller.retryLocalSend(pending);
          expect(adapter.mediaIds, [clientId, clientId]);
          expect(controller.localSends, isEmpty);
          expect(controller.messages.single.type, type);
          expect(await file.exists(), isFalse);
        } finally {
          controller.dispose();
          await directory.delete(recursive: true);
        }
      },
    );
  }

  test(
    'failed private image is cleaned up on disposal, after upload finishes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chat-delivery-dispose-',
      );
      final file = await File('${directory.path}/draft.bin').writeAsBytes([1]);
      final controller = ConversationPageController(
        DirectConversationDto.fromJson(adapter.stored!),
      );
      adapter.gate = Completer<void>();
      adapter.failNext = true;
      final upload = controller.sendAttachment(
        file,
        '50000000-0000-4000-8000-000000000002',
        const ChatAttachmentDto(type: 'IMAGE', size: 1),
        ownsFile: true,
      );
      final failure = expectLater(upload, throwsException);
      controller.dispose();
      expect(await file.exists(), isTrue);
      adapter.gate!.complete();
      await failure;
      expect(await file.exists(), isFalse);
      await directory.delete(recursive: true);
    },
  );

  test('ceramic send shows its local card before acknowledgement', () async {
    final controller = ConversationPageController(
      DirectConversationDto.fromJson(adapter.stored!),
    );
    addTearDown(controller.dispose);
    adapter.gate = Completer<void>();
    adapter.failNext = true;
    final send = controller.sendCeramic(
      42,
      preview: const ChatCeramicCardDto(available: true, title: 'Cup'),
    );
    expect(controller.localSends.single.message.ceramic!.title, 'Cup');
    adapter.gate!.complete();
    expect(await send, isFalse);
    await controller.retryLocalSend(controller.localSends.single);
    expect(controller.localSends, isEmpty);
    expect(controller.messages.single.type, 'CERAMIC');
  });

  test(
    'acknowledged first send stays visible when its history refresh fails',
    () async {
      final controller = ConversationPageController(
        DirectConversationDto.draft(
          UserProfileDto.fromJson(messaging.profileJson),
        ),
      );
      addTearDown(controller.dispose);
      adapter.failHistory = true;
      expect(await controller.send('First request'), isTrue);
      expect(controller.messages, isEmpty);
      expect(controller.localSends.single.acknowledged, isTrue);
      expect(controller.localSends.single.failed, isFalse);
      adapter.failHistory = false;
      await controller.load();
      expect(controller.localSends, isEmpty);
      expect(controller.messages.single.body, 'First request');
      expect(adapter.sendIds, hasLength(1));
    },
  );

  for (final retry in [true, false]) {
    test(
      'failed locked voice local row ${retry ? 'retries' : 'cancels'} with its recording draft',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'chat-voice-delivery-',
        );
        final file = await File(
          '${directory.path}/voice.m4a',
        ).writeAsBytes([1, 2, 3, 4]);
        final controller = ConversationPageController(
          DirectConversationDto.fromJson(adapter.stored!),
        );
        var now = DateTime(2026, 10, 3);
        late ChatVoiceDraftController voice;
        voice = ChatVoiceDraftController(
          recorder: media.FakeRecorder(),
          createFile: () async => file,
          now: () => now,
          canSend: () => !controller.isSending,
          upload: (draft, id) => controller.sendAttachment(
            draft,
            id,
            ChatAttachmentDto(
              type: 'VOICE',
              size: 4,
              durationMs: voice.duration.inMilliseconds,
            ),
            retry: () => voice.send(),
          ),
          onSent: (_) {},
          onDiscard: controller.removeLocalFile,
        );
        try {
          await voice.start(lock: true);
          now = now.add(const Duration(seconds: 5));
          adapter.failNext = true;
          await voice.finishRecording();
          expect(voice.phase, VoiceDraftPhase.preview);
          expect(controller.localSends.single.failed, isTrue);
          expect(
            controller.localSends.single.message.attachment!.durationMs,
            5000,
          );
          expect(await file.exists(), isTrue);
          if (retry) {
            await controller.retryLocalSend(controller.localSends.single);
            expect(adapter.mediaIds.toSet(), hasLength(1));
            expect(controller.messages.single.type, 'VOICE');
          } else {
            await voice.cancel();
            expect(controller.messages, isEmpty);
          }
          expect(controller.localSends, isEmpty);
          expect(voice.phase, VoiceDraftPhase.idle);
          expect(await file.exists(), isFalse);
        } finally {
          voice.dispose();
          controller.dispose();
          await directory.delete(recursive: true);
        }
      },
    );
  }
}
