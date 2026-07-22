import 'dart:async';
import 'dart:convert';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/api/chat_socket_connector.dart';
import 'package:ceramic_app/config/constants/app_constants.dart';
import 'package:ceramic_app/objects/chat_event_dto.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatEventService with WidgetsBindingObserver {
  ChatEventService._();

  static final ChatEventService instance = ChatEventService._();

  final StreamController<ChatEventDto> _events = StreamController.broadcast();
  final ChatEventDeduplicator _deduplicator = ChatEventDeduplicator();
  Stream<ChatEventDto> get events => _events.stream;

  VoidCallback? onInvalidated;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _running = false;
  bool _foreground = true;
  int _generation = 0;
  int _attempt = 0;
  bool _observingLifecycle = false;

  void start() {
    if (_running) return;
    _running = true;
    _deduplicator.clear();
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
    _connect(++_generation);
  }

  Future<void> stop() async {
    _running = false;
    _generation++;
    _attempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _deduplicator.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (!foreground) {
      _generation++;
      _reconnectTimer?.cancel();
      _subscription?.cancel();
      _subscription = null;
      _channel?.sink.close();
      _channel = null;
    } else if (_running) {
      _attempt = 0;
      _connect(++_generation);
    }
  }

  Future<void> _connect(int generation) async {
    if (!_running || !_foreground || generation != _generation) return;
    WebSocketChannel? pendingChannel;
    try {
      final base = Uri.parse(AppConstants.api.apiDomain);
      final cookies = await ApiClient.cookieJar.loadForRequest(base);
      final cookieHeader = cookies.isEmpty
          ? null
          : cookies
                .map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; ');
      final socketUri = base.replace(
        scheme: base.scheme == 'https' ? 'wss' : 'ws',
        path: '${base.path.replaceFirst(RegExp(r'/$'), '')}/api/chat/events',
        query: null,
        fragment: null,
      );
      final channel = connectChatSocket(socketUri, cookieHeader);
      pendingChannel = channel;
      await channel.ready.timeout(const Duration(seconds: 10));
      if (!_running || !_foreground || generation != _generation) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      pendingChannel = null;
      _attempt = 0;
      _emit(ChatEventDto.reconcile());
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (_) => _disconnected(generation),
        onDone: () => _disconnected(generation),
        cancelOnError: true,
      );
    } catch (_) {
      await pendingChannel?.sink.close();
      _disconnected(generation);
    }
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final event = ChatEventDto.fromJson(decoded);
      if (_deduplicator.accept(event.eventId)) _emit(event);
    } catch (_) {
      // Malformed or unknown events are ignored; REST remains authoritative.
    }
  }

  void _emit(ChatEventDto event) {
    _events.add(event);
    onInvalidated?.call();
  }

  void _disconnected(int generation) {
    if (generation != _generation) return;
    final nextGeneration = ++_generation;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    if (!_running || !_foreground) return;
    onInvalidated?.call();
    final seconds = <int>[1, 2, 4, 8, 15, 30][_attempt.clamp(0, 5)];
    _attempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: seconds),
      () => _connect(nextGeneration),
    );
  }
}
