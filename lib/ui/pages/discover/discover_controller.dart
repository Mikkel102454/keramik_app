import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/repositories/publication_repository.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:flutter/foundation.dart';

class DiscoverController extends ChangeNotifier {
  DiscoverController(this.mode);
  final String mode;
  final List<PublicationCardDto> items = [];
  String? nextCursor;
  bool loading = false;
  Object? error;

  Future<bool> load({bool refresh = false}) async {
    if (loading) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await PublicationRepository.discover(
        mode,
        cursor: refresh ? null : nextCursor,
      );
      if (refresh) items.clear();
      final known = items.map((item) => item.publicationId).toSet();
      items.addAll(page.items.where((item) => known.add(item.publicationId)));
      nextCursor = page.nextCursor;
      return true;
    } on ApiException catch (exception) {
      if (exception.code == 'DISCOVER_SESSION_EXPIRED') {
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
      items[index] = await PublicationRepository.like(original, !original.likedByMe);
    } catch (_) {
      items[index] = original;
    }
    notifyListeners();
  }

  Future<PublicationCardDto?> hide(int index) async {
    final removed = items.removeAt(index);
    notifyListeners();
    try {
      await PublicationRepository.notInterested(removed.publicationId, true);
    } catch (_) {
      items.insert(index.clamp(0, items.length), removed);
      notifyListeners();
      rethrow;
    }
    return removed;
  }

  Future<void> undoHide(int index, PublicationCardDto item) async {
    await PublicationRepository.notInterested(item.publicationId, false);
    items.insert(index.clamp(0, items.length), item);
    notifyListeners();
  }
}
