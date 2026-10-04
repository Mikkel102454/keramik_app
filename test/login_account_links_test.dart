import 'dart:async';

import 'package:ceramic_app/config/constants/app_constants.dart';
import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/ui/pages/login/login_page.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _Launcher extends UrlLauncherPlatform {
  final List<String> urls = [];
  final List<LaunchOptions> options = [];
  Future<bool> Function()? result;
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    this.options.add(options);
    return result == null ? true : await result!();
  }
}

class _Authentication extends AuthenticationCubit {
  _Authentication()
    : super(dio: Dio(), cookieJar: PersistCookieJar(persistSession: false));
  String identifier = '';
  String password = '';
  int logins = 0;
  int cancellations = 0;
  @override
  void identifierChanged(String value) => identifier = value;
  @override
  void passwordChanged(String value) => password = value;
  @override
  Future<void> login() async => logins++;
  @override
  Future<void> cancelDeletion() async {
    cancellations++;
    emit(const AuthenticationState.loading());
    await Future<void>.value();
    emit(
      const AuthenticationState.error('private cancellation backend detail'),
    );
  }
}

void main() {
  late _Launcher launcher;
  late _Authentication authentication;
  setUp(() {
    final original = UrlLauncherPlatform.instance;
    launcher = _Launcher();
    UrlLauncherPlatform.instance = launcher;
    authentication = _Authentication();
    addTearDown(() => UrlLauncherPlatform.instance = original);
    addTearDown(authentication.close);
  });

  Future<void> show(WidgetTester tester, {String language = 'en'}) async {
    await tester.pumpWidget(
      BlocProvider<AuthenticationCubit>.value(
        value: authentication,
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginPage(),
        ),
      ),
    );
  }

  testWidgets(
    'pending deletion cancellation errors keep safe recovery controls',
    (tester) async {
      authentication.deletionPending = true;
      await show(tester);
      await tester.ensureVisible(find.text('Cancel deletion'));
      await tester.pump();
      await tester.tap(find.text('Cancel deletion'));
      await tester.pumpAndSettle();
      expect(
        find.text('That action could not be completed. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('private cancellation backend detail'),
        findsNothing,
      );
      expect(find.text('Account deletion pending'), findsOneWidget);
      expect(authentication.deletionPending, isTrue);
      expect(authentication.cancellations, 1);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Cancel deletion'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account buttons launch clean website URLs externally', (
    tester,
  ) async {
    await show(tester);
    await tester.enterText(
      find.byType(TextField).at(0),
      'private@example.invalid',
    );
    await tester.enterText(find.byType(TextField).at(1), 'not-sent-to-browser');
    await tester.ensureVisible(find.text('Forgot password'));
    await tester.pump();
    await tester.tap(find.text('Forgot password'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign up'));
    await tester.pump();
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(launcher.urls, [
      AppConstants.api.forgotPasswordUrl,
      AppConstants.api.signupUrl,
    ]);
    for (final url in launcher.urls) {
      final uri = Uri.parse(url);
      expect(uri.userInfo, isEmpty);
      expect(uri.query, isEmpty);
      expect(uri.fragment, isEmpty);
      expect(uri.host, Uri.parse(AppConstants.api.membershipUrl).host);
    }
    expect(Uri.parse(launcher.urls[0]).path, '/forgot-password');
    expect(Uri.parse(launcher.urls[1]).path, '/signup');
    expect(
      launcher.options.every(
        (o) => o.mode == PreferredLaunchMode.externalApplication,
      ),
      isTrue,
    );
    expect(authentication.logins, 0);
  });

  testWidgets('pending launch blocks duplicate and other account launches', (
    tester,
  ) async {
    final pending = Completer<bool>();
    launcher.result = () => pending.future;
    await show(tester);
    await tester.ensureVisible(find.text('Forgot password'));
    await tester.pump();
    await tester.tap(find.text('Forgot password'));
    await tester.pump();
    await tester.ensureVisible(find.text('Forgot password'));
    await tester.pump();
    await tester.tap(find.text('Forgot password'));
    await tester.ensureVisible(find.text('Sign up'));
    await tester.pump();
    await tester.tap(find.text('Sign up'));
    expect(launcher.urls, hasLength(1));
    pending.complete(true);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign up'));
    await tester.pump();
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(launcher.urls, hasLength(2));
  });

  for (final language in ['en', 'da']) {
    testWidgets('launch failure is localized and allows retry ($language)', (
      tester,
    ) async {
      launcher.result = () async => false;
      await show(tester, language: language);
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      await tester.ensureVisible(find.text(l10n.forgotPassword));
      await tester.pump();
      await tester.tap(find.text(l10n.forgotPassword));
      await tester.pumpAndSettle();
      expect(find.text(l10n.accountWebsiteOpenFailed), findsOneWidget);
      launcher.result = () async => throw StateError('platform failure');
      await tester.ensureVisible(find.text(l10n.forgotPassword));
      await tester.pump();
      await tester.tap(find.text(l10n.forgotPassword));
      await tester.pumpAndSettle();
      expect(launcher.urls, hasLength(2));
    });
  }

  testWidgets(
    'account controls have button semantics and normal login still works',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await show(tester);
      await tester.ensureVisible(find.text('Forgot password'));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Forgot password')),
        matchesSemantics(
          label: 'Forgot password',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      await tester.ensureVisible(find.text('Sign up'));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Sign up')),
        matchesSemantics(
          label: 'Sign up',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      await tester.enterText(find.byType(TextField).at(0), 'existing-member');
      await tester.enterText(find.byType(TextField).at(1), 'existing-password');
      await tester.ensureVisible(find.text('Log in'));
      await tester.pump();
      await tester.tap(find.text('Log in'));
      expect(authentication.identifier, 'existing-member');
      expect(authentication.password, 'existing-password');
      expect(authentication.logins, 1);
      expect(launcher.urls, isEmpty);
      semantics.dispose();
    },
  );
}
