import 'dart:async';

import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/ui/pages/settings/account_settings_pages.dart';
import 'package:ceramic_app/ui/pages/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first launch is English and cached locale restores before the app', () async {
    final first = AppSettingsController(localeCache: _MemoryLocaleCache());
    await first.initializeLocale();
    expect(first.locale, const Locale('en'));
    expect(first.settings.languageTag, 'en');

    final restored = AppSettingsController(
      localeCache: _MemoryLocaleCache('da'),
    );
    await restored.initializeLocale();
    expect(restored.locale, const Locale('da'));
    expect(restored.settings.languageTag, 'da');
  });

  test('unsupported tags display English without losing the original tag',
      () async {
    final cache = _MemoryLocaleCache('zz-ZZ');
    final controller = AppSettingsController(localeCache: cache);
    await controller.initializeLocale();

    expect(controller.locale, const Locale('en'));
    expect(controller.settings.languageTag, 'zz-ZZ');
    expect(cache.value, 'zz-ZZ');

    await controller.applyAccountSettings(
      const AccountSettingsDto(languageTag: 'future-Latn'),
    );
    expect(controller.locale, const Locale('en'));
    expect(controller.settings.languageTag, 'future-Latn');
    expect(cache.value, 'future-Latn');
  });

  test('authenticated account overrides cache and logout retains language',
      () async {
    final cache = _MemoryLocaleCache('en');
    final controller = AppSettingsController(
      localeCache: cache,
      settingsLoader: () async =>
          const AccountSettingsDto(languageTag: 'da'),
    );
    await controller.initializeLocale();
    await controller.load();

    expect(controller.locale, const Locale('da'));
    expect(cache.value, 'da');

    controller.resetForLogout();
    expect(controller.locale, const Locale('da'));
    expect(controller.settings.languageTag, 'da');
  });

  test('DTO preserves unknown language tags through JSON round trips', () {
    final settings = AccountSettingsDto.fromJson(const {
      'languageTag': 'fr-CA',
    });

    expect(settings.languageTag, 'fr-CA');
    expect(settings.toJson()['languageTag'], 'fr-CA');
    expect(
      AccountSettingsDto.fromJson(settings.toJson()).languageTag,
      'fr-CA',
    );
  });

  testWidgets('selector discovers native names and switches immediately',
      (tester) async {
    final cache = _MemoryLocaleCache('en');
    final appSettings = AppSettingsController(localeCache: cache);
    await appSettings.initializeLocale();
    final saveCompleter = Completer<AccountSettingsDto>();
    final controller = SettingsController(
      loader: () async => const AccountSettingsDto(languageTag: 'en'),
      saver: (_) => saveCompleter.future,
      appSettings: appSettings,
    );
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      _localizedHarness(
        appSettings,
        LanguageSettingsPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Dansk'), findsOneWidget);
    expect(find.text('German'), findsNothing);

    await tester.tap(find.text('Dansk'));
    await tester.pump();
    expect(appSettings.locale, const Locale('da'));
    expect(cache.value, 'da');

    saveCompleter.complete(
      const AccountSettingsDto(languageTag: 'da'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nuværende sprog'), findsOneWidget);
  });

  testWidgets('failed language save rolls UI and cache back', (tester) async {
    final cache = _MemoryLocaleCache('en');
    final appSettings = AppSettingsController(localeCache: cache);
    await appSettings.initializeLocale();
    final saveCompleter = Completer<AccountSettingsDto>();
    final controller = SettingsController(
      loader: () async => const AccountSettingsDto(languageTag: 'en'),
      saver: (_) => saveCompleter.future,
      appSettings: appSettings,
    );
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      _localizedHarness(
        appSettings,
        LanguageSettingsPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dansk'));
    await tester.pump();
    expect(appSettings.locale, const Locale('da'));

    saveCompleter.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(appSettings.locale, const Locale('en'));
    expect(cache.value, 'en');
    expect(find.textContaining('previous language was restored'), findsOneWidget);
    expect(find.text('Current language'), findsOneWidget);
  });
}

Widget _localizedHarness(
  AppSettingsController settings,
  Widget home,
) {
  return AnimatedBuilder(
    animation: settings,
    builder: (context, _) => MaterialApp(
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

class _MemoryLocaleCache implements LocaleCache {
  _MemoryLocaleCache([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String languageTag) async {
    value = languageTag;
  }
}
