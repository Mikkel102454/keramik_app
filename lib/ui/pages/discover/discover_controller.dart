import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/repositories/publication_repository.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:flutter/foundation.dart';

typedef DiscoverPageLoader =
    Future<DiscoverPageDto> Function(
      String mode, {
      String? cursor,
      String? requestId,
    });
typedef PublicationLikeUpdater =
    Future<PublicationCardDto> Function(PublicationCardDto card, bool liked);
typedef NotInterestedUpdater =
    Future<void> Function(String publicationId, bool hidden);

class DiscoverController extends ChangeNotifier {
  DiscoverController(
    this.mode, {
    DiscoverPageLoader? pageLoader,
    PublicationLikeUpdater? likeUpdater,
    NotInterestedUpdater? notInterestedUpdater,
  }) : _pageLoader = pageLoader ?? PublicationRepository.discover,
       _likeUpdater = likeUpdater ?? PublicationRepository.like,
       _notInterestedUpdater =
           notInterestedUpdater ?? PublicationRepository.notInterested;

  final String mode;
  final DiscoverPageLoader _pageLoader;
  final PublicationLikeUpdater _likeUpdater;
  final NotInterestedUpdater _notInterestedUpdater;
  final List<PublicationCardDto> items = [];
  String? nextCursor;
  String? _pendingCursor;
  String? _pendingRequestId;
  bool loading = false;
  Object? error;

  Future<bool> load({bool refresh = false}) async {
    if (loading) return false;
    loading = true;
    error = null;
    notifyListeners();
    final requestCursor = refresh ? null : nextCursor;
    if (_pendingRequestId == null || _pendingCursor != requestCursor) {
      _pendingCursor = requestCursor;
      _pendingRequestId = createClientUuid();
    }
    try {
      final page = await _pageLoader(
        mode,
        cursor: requestCursor,
        requestId: _pendingRequestId,
      );
      _pendingCursor = null;
      _pendingRequestId = null;
      if (refresh) items.clear();
      final known = items.map((item) => item.publicationId).toSet();
      items.addAll(page.items.where((item) => known.add(item.publicationId)));
      nextCursor = page.nextCursor;
      return true;
    } on ApiException catch (exception) {
      if (exception.code == 'DISCOVER_SESSION_EXPIRED') {
        _pendingCursor = null;
        _pendingRequestId = null;
        items.clear();
        nextCursor = null;
        loading = false;
        notifyListeners();
        return load(refresh: true);
      }
      error = exception;
      return false;
    } catch (exception) {
      error = exception;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int index) async {
    final original = items[index];
    if (original.ownedByMe) return;
    items[index] = original.copyWith(
      likedByMe: !original.likedByMe,
      likeCount: original.likeCount + (original.likedByMe ? -1 : 1),
    );
    notifyListeners();
    try {
      final updated = await _likeUpdater(original, !original.likedByMe);
      final currentIndex = items.indexWhere(
        (item) => item.publicationId == original.publicationId,
      );
      if (currentIndex >= 0) items[currentIndex] = updated;
    } catch (_) {
      final currentIndex = items.indexWhere(
        (item) => item.publicationId == original.publicationId,
      );
      if (currentIndex >= 0) items[currentIndex] = original;
    }
    notifyListeners();
  }

  Future<PublicationCardDto?> hide(int index) async {
    final removed = items.removeAt(index);
    notifyListeners();
    try {
      await _notInterestedUpdater(removed.publicationId, true);
    } catch (_) {
      items.insert(index.clamp(0, items.length), removed);
      notifyListeners();
      rethrow;
    }
    return removed;
  }

  Future<void> undoHide(int index, PublicationCardDto item) async {
    await _notInterestedUpdater(item.publicationId, false);
    if (items.every((value) => value.publicationId != item.publicationId)) {
      items.insert(index.clamp(0, items.length), item);
    }
    notifyListeners();
  }
}
