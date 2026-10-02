import 'package:ceramic_app/utils/web.dart';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/glaze_notebook_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';
import 'package:ceramic_app/repositories/glaze_notebook_repository.dart';

/// One logical application retains its identity until a confirmed success.
class CombinationApplicationController {
  static final Map<int, CombinationApplicationController> _pendingByPiece = {};
  static CombinationApplicationController forPiece(int pieceId) =>
      _pendingByPiece[pieceId] ?? CombinationApplicationController();
  static CombinationApplicationController? forRecipe(int recipeId) =>
      _pendingByPiece.values
          .where((c) => c.pending?.id == recipeId)
          .firstOrNull;
  static void clearSession() => _pendingByPiece.clear();
  GlazeNotebookDto? pending;
  String? requestId;
  int? pendingPieceId;
  bool conflict = false;
  bool busy = false;
  void begin(GlazeNotebookDto recipe, int pieceId) {
    if (pending != null) return;
    pending = recipe;
    pendingPieceId = pieceId;
    _pendingByPiece[pieceId] = this;
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    requestId =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<bool> apply(Future<void> Function() refresh) async {
    if (busy || pending == null) return false;
    busy = true;
    conflict = false;
    try {
      await GlazeNotebookRepository.apply(
        pendingPieceId!,
        pending!.id,
        pending!.version,
        requestId!,
      );
      await refresh();
      _pendingByPiece.remove(pendingPieceId);
      pending = null;
      requestId = null;
      pendingPieceId = null;
      return true;
    } catch (e) {
      conflict =
          (e is DioException && e.response?.statusCode == 409) ||
          (e is ApiException && e.statusCode == 409);
      if (conflict) {
        _pendingByPiece.remove(pendingPieceId);
        pending = null;
        requestId = null;
        pendingPieceId = null;
      }
      return false;
    } finally {
      busy = false;
    }
  }

  Future<List<CeramicDto>> pieces() => CeramicRepository.getCeramics();
  Future<CeramicDto> piece(int id) => CeramicRepository.getCeramic(id);
}
