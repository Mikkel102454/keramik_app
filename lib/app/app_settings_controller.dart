import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/repositories/account_repository.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

typedef AccountSettingsLoader = Future<AccountSettingsDto> Function();

abstract interface class LocaleCache {
  Future<String?> read();
  Future<void> write(String languageTag);
}

class FileLocaleCache implements LocaleCache {
  static const _fileName = 'language-tag.txt';

  @override
  Future<String?> read() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}$_fileName');
      if (!await file.exists()) return null;
      final value = (await file.readAsString()).trim();
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String languageTag) async {
    try {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      final file = File('${directory.path}${Platform.pathSeparator}$_fileName');
      await file.writeAsString(languageTag, flush: true);
    } catch (_) {
      // Locale changes still work for the active session when local storage is
      // temporarily unavailable.
    }
  }
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    LocaleCache? localeCache,
    AccountSettingsLoader? settingsLoader,
  }) : _localeCache = localeCache ?? FileLocaleCache(),
       _settingsLoader = settingsLoader ?? AccountRepository.getSettings;

  static final AppSettingsController instance = AppSettingsController();

  final LocaleCache _localeCache;
  final AccountSettingsLoader _settingsLoader;

  AccountSettingsDto _settings = const AccountSettingsDto();
  Locale _locale = const Locale('en');
  String _lastLanguageTag = 'en';

  AccountSettingsDto get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode.themeMode;
  MeasurementSystem get measurementSystem => _settings.measurementSystem;
  String get preferredCurrency => _settings.preferredCurrency == 'AUTO'
      ? detectedCurrency(PlatformDispatcher.instance.locale)
      : _settings.preferredCurrency;
  Locale get locale => _locale;

  Future<void> initializeLocale() async {
    final cached = await _localeCache.read();
    if (cached == null) return;
    _lastLanguageTag = cached;
    _settings = _settings.copyWith(languageTag: cached);
    _locale = resolveSupportedLocale(cached);
  }

  Future<void> load() async {
    try {
      await applyAccountSettings(await _settingsLoader());
    } catch (_) {
      // Cached/default locale and legacy settings remain usable. Settings pages
      // expose a recoverable load error when opened.
    }
  }

  Future<void> applyAccountSettings(AccountSettingsDto value) async {
    await _apply(value, cacheLanguage: true);
  }

  Future<void> applyLocalSettings(AccountSettingsDto value) async {
    await _apply(value, cacheLanguage: true);
  }

  Future<void> _apply(
    AccountSettingsDto value, {
    required bool cacheLanguage,
  }) async {
    _settings = value;
    _lastLanguageTag = value.languageTag;
    _locale = resolveSupportedLocale(value.languageTag);
    notifyListeners();
    if (cacheLanguage) await _localeCache.write(value.languageTag);
  }

  void resetForLogout() {
    _settings = AccountSettingsDto(languageTag: _lastLanguageTag);
    notifyListeners();
  }

  @visibleForTesting
  static Locale resolveSupportedLocale(String languageTag) {
    final normalized = languageTag.toLowerCase();
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.toLanguageTag().toLowerCase() == normalized) return locale;
    }
    return const Locale('en');
  }
}
