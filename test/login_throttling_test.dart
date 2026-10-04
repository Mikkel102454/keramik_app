import 'dart:io';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/ui/pages/login/login_page.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '429 through the shared API client preserves cookies and never expires the session',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'login-rate-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => directory.path);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await ApiClient.init();
      ApiClient.dio.httpClientAdapter = _ThrottledAdapter('12');
      int expired = 0;
      ApiClient.onUnauthorized = () => expired++;
      addTearDown(() => ApiClient.onUnauthorized = null);
      final uri = Uri.parse('${ApiClient.dio.options.baseUrl}/api/auth/login');
      await ApiClient.cookieJar.saveFromResponse(uri, [
        Cookie('JSESSIONID', 'isolated-test-session'),
      ]);
      final cubit = AuthenticationCubit();
      addTearDown(cubit.close);
      cubit.identifierChanged('potter');
      cubit.passwordChanged('unused-test-password');
      await cubit.login();
      expect(
        cubit.state,
        const AuthenticationState.error(
          AuthenticationCubit.loginThrottledMessage,
        ),
      );
      expect(cubit.loginRetryAfterSeconds, 12);
      expect(expired, 0);
      expect(
        (await ApiClient.cookieJar.loadForRequest(uri)).single.value,
        'isolated-test-session',
      );
    },
  );

  test(
    'Dio throwing 429 is still throttling and malformed retry headers use generic feedback',
    () async {
      for (final retry in [null, 'invalid', '-1', '0']) {
        final dio = Dio()..httpClientAdapter = _ThrottledAdapter(retry);
        final cubit = AuthenticationCubit(
          dio: dio,
          cookieJar: PersistCookieJar(persistSession: false),
        );
        addTearDown(cubit.close);
        cubit.identifierChanged('potter');
        cubit.passwordChanged('unused-test-password');
        await cubit.login();
        expect(
          cubit.state,
          const AuthenticationState.error(
            AuthenticationCubit.loginThrottledMessage,
          ),
        );
        expect(cubit.loginRetryAfterSeconds, isNull);
      }
    },
  );

  for (final language in ['en', 'da']) {
    testWidgets('login retry feedback is localized and announced in $language', (
      tester,
    ) async {
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = _ThrottledAdapter('12');
      final cubit = AuthenticationCubit(
        dio: dio,
        cookieJar: PersistCookieJar(persistSession: false),
      );
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
      cubit.identifierChanged('potter');
      cubit.passwordChanged('unused-test-password');
      await tester.runAsync(cubit.login);
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      expect(find.text(l10n.loginThrottledRetry(12)), findsOneWidget);
      expect(find.text('private server details'), findsNothing);
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.text(l10n.loginThrottledRetry(12))).label,
        contains(l10n.loginThrottledRetry(12)),
      );
      semantics.dispose();
      // The same page can retry; the transport does not impose a local account lockout.
      ScaffoldMessenger.of(
        tester.element(find.byType(LoginPage)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      dio.httpClientAdapter = _ThrottledAdapter(null);
      await tester.runAsync(cubit.login);
      await tester.pumpAndSettle();
      expect(find.text(l10n.loginThrottled), findsOneWidget);
    });
  }
}

class _ThrottledAdapter implements HttpClientAdapter {
  _ThrottledAdapter(this.retry);
  final String? retry;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"success":false,"error":{"code":"RATE_LIMITED","message":"private server details"}}',
    429,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      if (retry != null) 'retry-after': [retry!],
    },
  );
  @override
  void close({bool force = false}) {}
}
