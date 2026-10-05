import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Installed versionCode, rather than a user-editable locale or a cached policy.
class InstalledClient {
  static Map<String, String> headers = {};
  static int? versionCode;
  static Future<void> initialize() async {
    final info = await PackageInfo.fromPlatform();
    final code = int.tryParse(info.buildNumber);
    if (code == null || code < 1 || info.packageName != 'nu.miguel.claydock') {
      throw StateError('Cannot verify the installed ClayDock identity/version');
    }
    versionCode = code;
    headers = {
      'X-ClayDock-Platform': 'android',
      'X-ClayDock-Version-Code': '$code',
    };
  }
}

class ClientPolicy {
  ClientPolicy.fromJson(Map<String, dynamic> json)
    : latest = _positive(json['latestVersionCode']),
      minimum = _positive(json['minimumVersionCode']),
      deadline = json['mandatoryAt'] == null
          ? null
          : DateTime.parse(json['mandatoryAt'] as String).toUtc(),
      storeUrl = Uri.parse(json['storeUrl'] as String) {
    if (json['schemaVersion'] != 1 ||
        minimum > latest ||
        storeUrl.toString() !=
            'https://play.google.com/store/apps/details?id=nu.miguel.claydock') {
      throw const FormatException('Unsupported update policy');
    }
    final available = json['availableAt'] == null
        ? null
        : DateTime.parse(json['availableAt'] as String).toUtc();
    if ((available == null) != (deadline == null) ||
        (available != null &&
            deadline!.difference(available) != const Duration(days: 7))) {
      throw const FormatException('Invalid update deadline');
    }
  }
  final int latest;
  final int minimum;
  final DateTime? deadline;
  final Uri storeUrl;
  static int _positive(dynamic value) {
    if (value is! int || value < 1) {
      throw const FormatException('Invalid version');
    }
    return value;
  }
}

enum VersionVerification { checking, verified, unavailable, updateRequired }

class ClientVersionController extends ChangeNotifier
    with WidgetsBindingObserver {
  ClientVersionController({required Dio dio, required int versionCode})
    : _dio = dio,
      installed = versionCode;
  final Dio _dio;
  final int installed;
  ClientPolicy? policy;
  VersionVerification state = VersionVerification.checking;
  Timer? _timer;
  bool _disposed = false;
  Future<void>? _inFlight;
  bool get mayEnter => state == VersionVerification.verified;
  bool get updateAvailable =>
      mayEnter && policy != null && installed < policy!.latest;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    verify();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => verify());
  }

  Future<void> verify() =>
      _inFlight ??= _verify().whenComplete(() => _inFlight = null);
  Future<void> _verify() async {
    try {
      if (installed < 1) {
        throw const FormatException('Installed version unavailable');
      }
      final response = await _dio.get(
        '/api/client-policy',
        options: Options(
          headers: {'Cache-Control': 'no-cache'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode != 200 ||
          response.data is! Map ||
          response.data['data'] is! Map) {
        throw const FormatException('Unavailable policy');
      }
      final next = ClientPolicy.fromJson(
        Map<String, dynamic>.from(response.data['data']),
      );
      if (_disposed) return;
      policy = next;
      state = installed < next.minimum
          ? VersionVerification.updateRequired
          : VersionVerification.verified;
    } catch (_) {
      if (_disposed) return;
      state = VersionVerification.unavailable;
    }
    notifyListeners();
  }

  void requireVerification({required bool outdated}) {
    state = outdated
        ? VersionVerification.updateRequired
        : VersionVerification.unavailable;
    notifyListeners();
    verify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) verify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
