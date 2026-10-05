import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clay_dock/objects/entitlement_dto.dart';
import 'package:clay_dock/repositories/entitlement_repository.dart';

class EntitlementController extends ChangeNotifier with WidgetsBindingObserver {
  EntitlementController({Future<EntitlementDto> Function()? load})
    : _load = load ?? EntitlementRepository.load;
  static final instance = EntitlementController();
  final Future<EntitlementDto> Function() _load;
  EntitlementDto? value;
  bool active = false;
  bool loading = false;
  bool failed = false;
  int _generation = 0;
  Future<void>? _pending;

  void start() {
    reset();
    active = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
  }

  void reset() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    active = false;
    value = null;
    loading = false;
    failed = false;
    _pending = null;
    notifyListeners();
  }

  Future<void> refresh() {
    if (!active) return Future.value();
    return _pending ??= _refresh(_generation);
  }

  Future<void> _refresh(int generation) async {
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final result = await Future.sync(
        _load,
      ).timeout(const Duration(seconds: 20));
      if (generation == _generation) value = result;
    } catch (_) {
      if (generation == _generation) failed = true;
    } finally {
      if (generation == _generation) {
        loading = false;
        _pending = null;
        notifyListeners();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && active) unawaited(refresh());
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
