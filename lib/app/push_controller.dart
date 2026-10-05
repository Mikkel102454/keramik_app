import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clay_dock/repositories/push_repository.dart';
import 'package:clay_dock/api/chat_event_service.dart';
import 'package:clay_dock/utils/client_uuid.dart';

class PushController extends ChangeNotifier with WidgetsBindingObserver {
  PushController._();
  static final instance = PushController._();
  File? _stateFile;
  String _installation = '';
  bool optedIn = false;
  bool available = false;
  bool busy = false;
  bool failed = false;
  bool _authenticated = false;
  String? _pendingEvent;
  AuthorizationStatus permission = AuthorizationStatus.notDetermined;
  Future<void> Function(Map<String, dynamic>)? onTap;
  bool get configured =>
      !kIsWeb &&
      Platform.isAndroid &&
      const String.fromEnvironment('FCM_APP_ID').isNotEmpty;

  Future<void> initialize() async {
    if (!configured) return;
    try {
      _stateFile = File(
        '${(await getApplicationSupportDirectory()).path}/push-device.json',
      );
      if (await _stateFile!.exists()) {
        final state = jsonDecode(await _stateFile!.readAsString());
        _installation = state['installation'] as String;
        optedIn = state['enabled'] == true;
      } else {
        _installation = createClientUuid();
        await _persist();
      }
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FCM_API_KEY'),
          appId: String.fromEnvironment('FCM_APP_ID'),
          messagingSenderId: String.fromEnvironment('FCM_SENDER_ID'),
          projectId: String.fromEnvironment('FCM_PROJECT_ID'),
        ),
      );
      await FirebaseMessaging.instance.setAutoInitEnabled(optedIn);
      FirebaseMessaging.onMessage.listen((_) {
        if (_authenticated) ChatEventService.instance.reconcile();
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_tap);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        if (_authenticated && optedIn) {
          try {
            await PushRepository.register(_installation, token);
          } catch (_) {
            failed = true;
            notifyListeners();
          }
        }
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _pendingEvent = initial.data['eventId'] as String?;
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      failed = true;
    }
  }

  Future<void> start() async {
    _authenticated = true;
    await refresh();
    await _resolveTap();
  }

  void stop() {
    _authenticated = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _authenticated) {
      unawaited(refresh());
    }
  }

  Future<void> refresh() async {
    if (!configured || Firebase.apps.isEmpty || !_authenticated) return;
    try {
      available = await PushRepository.available();
      permission = (await FirebaseMessaging.instance.getNotificationSettings())
          .authorizationStatus;
      if (optedIn && available) {
        if (permission == AuthorizationStatus.authorized) {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await PushRepository.register(_installation, token);
          }
        } else {
          await PushRepository.remove(_installation);
        }
      }
      failed = false;
    } catch (_) {
      failed = true;
    }
    notifyListeners();
  }

  Future<void> enable() async {
    if (busy || !available || !_authenticated) return;
    busy = true;
    notifyListeners();
    try {
      permission = (await FirebaseMessaging.instance.requestPermission())
          .authorizationStatus;
      if (permission == AuthorizationStatus.authorized) {
        await FirebaseMessaging.instance.setAutoInitEnabled(true);
        final token = await FirebaseMessaging.instance.getToken();
        if (token == null) throw StateError('Token unavailable');
        await PushRepository.register(_installation, token);
        optedIn = true;
        await _persist();
      }
      failed = false;
    } catch (_) {
      failed = true;
    }
    busy = false;
    notifyListeners();
  }

  Future<void> disable() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      if (_installation.isNotEmpty && _authenticated) {
        await PushRepository.remove(_installation);
      }
      if (configured && Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
        await FirebaseMessaging.instance.deleteToken();
      }
      optedIn = false;
      await _persist();
      failed = false;
    } catch (_) {
      failed = true;
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (configured && Firebase.apps.isNotEmpty) await disable();
    _pendingEvent = null;
    _authenticated = false;
  }

  Future<void> openSettings() => const MethodChannel(
    'claydock/notifications',
  ).invokeMethod<void>('settings');
  Future<void> _persist() async {
    await _stateFile?.writeAsString(
      jsonEncode({'installation': _installation, 'enabled': optedIn}),
      flush: true,
    );
  }

  void _tap(RemoteMessage message) {
    _pendingEvent = message.data['eventId'] as String?;
    unawaited(_resolveTap());
  }

  Future<void> _resolveTap() async {
    if (!_authenticated || _pendingEvent == null || onTap == null) return;
    final event = _pendingEvent!;
    _pendingEvent = null;
    Map<String, dynamic> destination;
    try {
      destination = await PushRepository.resolve(event);
    } catch (_) {
      destination = {'destination': 'CHATS'};
    }
    if (_authenticated) await onTap!(destination);
  }
}
