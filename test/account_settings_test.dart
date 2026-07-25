import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_create/ceramic_create_page_controller.dart';
import 'package:ceramic_app/ui/pages/settings/settings_controller.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy settings defaults preserve current behavior', () {
    final settings = AccountSettingsDto.fromJson(const {});

    expect(settings.themeMode, AccountThemeMode.system);
    expect(settings.measurementSystem, MeasurementSystem.metric);
    expect(settings.languageTag, 'en');
    expect(settings.discoverability, PrivacyAudience.everyone);
    expect(settings.friendRequests, PrivacyAudience.everyone);
    expect(settings.messages, PrivacyAudience.everyone);
    expect(settings.notifyDirectMessages, isTrue);
    expect(settings.notifyMessageRequests, isTrue);
    expect(settings.notifyFriendRequests, isTrue);
    expect(settings.notifyGroupActivity, isTrue);
  });

  test('failed optimistic setting save restores the previous value', () async {
    const original = AccountSettingsDto();
    final controller = SettingsController(
      loader: () async => original,
      saver: (_) async => throw Exception('offline'),
      appSettings: AppSettingsController(localeCache: _TestLocaleCache()),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final saved = await controller.save(
      original.copyWith(themeMode: AccountThemeMode.dark),
    );

    expect(saved, isFalse);
    expect(controller.settings.themeMode, AccountThemeMode.system);
    expect(controller.error, SettingsError.saveFailed);
  });

  test('imperial conversions round-trip canonical values', () {
    final inches = Measurement.lengthFromCentimeters(
      25.4,
      MeasurementSystem.imperial,
    );
    expect(inches, closeTo(10, 0.0001));
    expect(
      Measurement.lengthToCentimeters(inches, MeasurementSystem.imperial),
      closeTo(25.4, 0.0001),
    );

    final fahrenheit = Measurement.temperatureFromCelsius(
      1000,
      MeasurementSystem.imperial,
    );
    expect(fahrenheit, closeTo(1832, 0.0001));
    expect(
      Measurement.temperatureToCelsius(
        fahrenheit,
        MeasurementSystem.imperial,
      ),
      closeTo(1000, 0.0001),
    );

    final pounds = Measurement.weightFromKilograms(
      10,
      MeasurementSystem.imperial,
    );
    expect(pounds, closeTo(22.0462, 0.0001));
    expect(
      Measurement.weightToKilograms(pounds, MeasurementSystem.imperial),
      closeTo(10, 0.0001),
    );
    expect(MeasurementSystem.metric.weightSymbol, 'kg');
    expect(MeasurementSystem.imperial.weightSymbol, 'lb');
  });

  test('ceramic weight input follows the active unit setting', () async {
    final appSettings = AppSettingsController.instance;
    final controller = CeramicCreatePageController();
    try {
      await appSettings.applyLocalSettings(
        const AccountSettingsDto(
          measurementSystem: MeasurementSystem.imperial,
        ),
      );

      controller.setWeight('22.0462');

      expect(controller.weight, closeTo(10, 0.0001));
    } finally {
      controller.dispose();
      await appSettings.applyLocalSettings(const AccountSettingsDto());
    }
  });

  test('account theme values map to the application theme modes', () {
    expect(AccountThemeMode.system.themeMode, ThemeMode.system);
    expect(AccountThemeMode.light.themeMode, ThemeMode.light);
    expect(AccountThemeMode.dark.themeMode, ThemeMode.dark);
  });
}

class _TestLocaleCache implements LocaleCache {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String languageTag) async {}
}
