import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/repositories/account_repository.dart';
import 'package:flutter/foundation.dart';

enum SettingsError { loadFailed, saveFailed }

typedef SettingsLoader = Future<AccountSettingsDto> Function();
typedef SettingsSaver = Future<AccountSettingsDto> Function(
  AccountSettingsDto settings,
);

class SettingsController extends ChangeNotifier {
  SettingsController({
    SettingsLoader? loader,
    SettingsSaver? saver,
    AppSettingsController? appSettings,
  })
    : _loader = loader ?? AccountRepository.getSettings,
      _saver = saver ?? AccountRepository.updateSettings,
      _appSettings = appSettings ?? AppSettingsController.instance;

  final SettingsLoader _loader;
  final SettingsSaver _saver;
  final AppSettingsController _appSettings;

  late AccountSettingsDto settings = _appSettings.settings;
  bool isLoading = false;
  bool isSaving = false;
  SettingsError? error;
  String get activeLanguageTag => _appSettings.locale.toLanguageTag();

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      settings = await _loader();
      await _appSettings.applyAccountSettings(settings);
    } catch (_) {
      error = SettingsError.loadFailed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(AccountSettingsDto next) async {
    if (isSaving || next == settings) return false;
    final previous = settings;
    settings = next;
    isSaving = true;
    error = null;
    await _appSettings.applyLocalSettings(next);
    notifyListeners();
    try {
      settings = await _saver(next);
      await _appSettings.applyAccountSettings(settings);
      return true;
    } catch (_) {
      settings = previous;
      await _appSettings.applyLocalSettings(previous);
      error = SettingsError.saveFailed;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
