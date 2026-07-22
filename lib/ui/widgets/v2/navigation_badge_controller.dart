import 'dart:async';

import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:flutter/foundation.dart';

class NavigationBadgeController {
  NavigationBadgeController._();

  static final NavigationBadgeController instance =
      NavigationBadgeController._();

  final ValueNotifier<int> count = ValueNotifier<int>(0);
  Future<void>? _refreshing;
  bool _refreshQueued = false;

  Future<void> refresh() {
    final active = _refreshing;
    if (active != null) {
      _refreshQueued = true;
      return active;
    }
    final operation = _load();
    _refreshing = operation;
    return operation.whenComplete(() {
      _refreshing = null;
      if (_refreshQueued) {
        _refreshQueued = false;
        unawaited(refresh());
      }
    });
  }

  Future<void> _load() async {
    try {
      setCount(await ChatRepository.getBadgeCount());
    } catch (_) {
      // Keep the last known count while offline or unauthenticated.
    }
  }

  void setCount(int value) {
    if (count.value != value) count.value = value;
  }
}
