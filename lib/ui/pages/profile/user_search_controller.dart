import 'dart:async';

import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:flutter/foundation.dart';

class UserSearchController extends ChangeNotifier {
  bool _disposed = false;
  Timer? _debounce;
  int _requestGeneration = 0;
  String query = '';
  List<UserProfileDto> results = const [];
  String? nextCursor;
  String? error;
  bool isLoading = false;
  bool isLoadingMore = false;

  void queryChanged(String value) {
    if (_disposed) return;
    query = value.trim();
    _debounce?.cancel();
    _requestGeneration++;
    if (query.runes.length < 3) {
      results = const [];
      nextCursor = null;
      error = null;
      isLoading = false;
      _notifySafely();
      return;
    }
    final generation = _requestGeneration;
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(generation));
    _notifySafely();
  }

  Future<void> retry() => _search(_requestGeneration);

  Future<void> _search(int generation) async {
    if (_disposed) return;
    isLoading = true;
    error = null;
    _notifySafely();
    try {
      final page = await SocialRepository.search(query);
      if (generation != _requestGeneration) return;
      results = page.items;
      nextCursor = page.nextCursor;
    } catch (exception) {
      if (generation != _requestGeneration) return;
      error = exception.toString();
    } finally {
      if (generation == _requestGeneration) {
        isLoading = false;
        _notifySafely();
      }
    }
  }

  Future<void> loadMore() async {
    if (_disposed) return;
    final cursor = nextCursor;
    if (cursor == null || isLoadingMore) return;
    isLoadingMore = true;
    _notifySafely();
    try {
      final page = await SocialRepository.search(query, cursor: cursor);
      results = [...results, ...page.items];
      nextCursor = page.nextCursor;
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoadingMore = false;
      _notifySafely();
    }
  }

  void removeResult(String userId) {
    if (_disposed) return;
    results = results.where((item) => item.userId != userId).toList();
    _notifySafely();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    _debounce?.cancel();
    super.dispose();
  }
}
