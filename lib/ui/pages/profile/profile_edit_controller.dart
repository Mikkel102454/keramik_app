import 'package:clay_dock/utils/network_timeout.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:clay_dock/objects/user_profile_dto.dart';
import 'package:clay_dock/repositories/account_repository.dart';
import 'package:clay_dock/utils/web.dart';

enum UsernameCheck {
  unchanged,
  waiting,
  checking,
  available,
  unavailable,
  failed,
}

/// Text belongs to this draft, independent of immediate photo refreshes.
class ProfileEditController extends ChangeNotifier {
  ProfileEditController(
    this.original, {
    Future<bool> Function(String)? checkUsername,
    Future<AccountProfileDto> Function(String, String, String)? saveProfile,
  }) : _check = checkUsername ?? AccountRepository.usernameAvailable,
       _save = saveProfile ?? AccountRepository.updateProfile,
       forename = original.forename,
       surname = original.surname,
       username = original.username;

  final AccountProfileDto original;
  final Future<bool> Function(String) _check;
  final Future<AccountProfileDto> Function(String, String, String) _save;
  String forename, surname, username;
  UsernameCheck usernameCheck = UsernameCheck.unchanged;
  bool saving = false, saveFailed = false, _disposed = false;
  bool saveTimedOut = false;
  Timer? _debounce;
  int _generation = 0;

  static bool validName(String value) =>
      value.trim().runes.isNotEmpty && value.trim().runes.length <= 100;
  static bool validUsername(String value) =>
      value.trim().runes.length >= 3 && value.trim().runes.length <= 50;
  bool get valid =>
      validName(forename) && validName(surname) && validUsername(username);
  bool get dirty =>
      forename.trim() != original.forename ||
      surname.trim() != original.surname ||
      username.trim() != original.username;
  bool get canSave =>
      !saving &&
      valid &&
      dirty &&
      (usernameCheck == UsernameCheck.unchanged ||
          usernameCheck == UsernameCheck.available);

  void changeNames({String? forename, String? surname}) {
    if (saving || _disposed) return;
    this.forename = forename ?? this.forename;
    this.surname = surname ?? this.surname;
    saveFailed = false;
    notifyListeners();
  }

  void changeUsername(String value) {
    if (saving || _disposed) return;
    username = value;
    saveFailed = false;
    _scheduleCheck();
  }

  void retryCheck() {
    if (saving || _disposed) return;
    _scheduleCheck();
  }

  void _scheduleCheck() {
    _debounce?.cancel();
    final generation = ++_generation;
    final value = username.trim();
    usernameCheck = value == original.username
        ? UsernameCheck.unchanged
        : UsernameCheck.waiting;
    if (validUsername(value) && usernameCheck != UsernameCheck.unchanged) {
      _debounce = Timer(
        const Duration(milliseconds: 500),
        () => _checkValue(value, generation),
      );
    }
    notifyListeners();
  }

  Future<void> _checkValue(String value, int generation) async {
    if (_disposed || generation != _generation) return;
    usernameCheck = UsernameCheck.checking;
    notifyListeners();
    try {
      final available = await _check(value);
      if (_disposed || generation != _generation) return;
      usernameCheck = available
          ? UsernameCheck.available
          : UsernameCheck.unavailable;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      usernameCheck = UsernameCheck.failed;
    }
    notifyListeners();
  }

  Future<AccountProfileDto?> save() async {
    if (!canSave || _disposed) return null;
    _debounce?.cancel();
    ++_generation;
    saving = true;
    saveFailed = false;
    saveTimedOut = false;
    notifyListeners();
    try {
      return await _save(forename.trim(), surname.trim(), username.trim());
    } catch (exception) {
      if (!_disposed) {
        if (exception is ApiException &&
            exception.code == 'USERNAME_UNAVAILABLE') {
          usernameCheck = UsernameCheck.unavailable;
        } else {
          saveFailed = true;
          saveTimedOut = isNetworkTimeout(exception);
        }
      }
      return null;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _debounce?.cancel();
    super.dispose();
  }
}
