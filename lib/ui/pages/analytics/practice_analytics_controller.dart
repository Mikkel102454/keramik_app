import 'package:ceramic_app/objects/practice_analytics_dto.dart';
import 'package:ceramic_app/repositories/practice_analytics_repository.dart';
import 'package:flutter/foundation.dart';

enum AnalyticsRange { days90, year, all }

typedef AnalyticsLoader =
    Future<PracticeAnalyticsDto> Function({DateTime? from, DateTime? to});

class PracticeAnalyticsController extends ChangeNotifier {
  PracticeAnalyticsController({AnalyticsLoader? loader})
    : _loader = loader ?? PracticeAnalyticsRepository.get;

  final AnalyticsLoader _loader;
  PracticeAnalyticsDto? data;
  AnalyticsRange range = AnalyticsRange.all;
  bool loading = false;
  Object? error;
  bool _disposed = false;

  Future<void> load({AnalyticsRange? selectedRange}) async {
    if (_disposed || loading) return;
    if (selectedRange != null) range = selectedRange;
    loading = true;
    error = null;
    _notify();
    final now = DateTime.now();
    final from = switch (range) {
      AnalyticsRange.days90 => now.subtract(const Duration(days: 90)),
      AnalyticsRange.year => now.subtract(const Duration(days: 365)),
      AnalyticsRange.all => null,
    };
    try {
      data = await _loader(
        from: from,
        to: range == AnalyticsRange.all ? null : now,
      );
    } catch (value) {
      error = value;
    } finally {
      loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
