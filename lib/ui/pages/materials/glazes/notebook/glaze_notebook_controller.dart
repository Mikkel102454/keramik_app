import 'package:ceramic_app/utils/web.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/glaze_notebook_dto.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'package:ceramic_app/repositories/glaze_notebook_repository.dart';

class GlazeNotebookController extends ChangeNotifier {
  GlazeNotebookController({required bool tiles})
    : repository = GlazeNotebookRepository(tiles: tiles);
  final GlazeNotebookRepository repository;
  List<GlazeNotebookDto> items = [];
  List<GlazeNotebookDto> recipes = [];
  final Map<int, String> recipeNames = {};
  List<ClayDto> clays = [];
  List<GlazeDto> glazes = [];
  String search = '';
  int? recipeId;
  int? clayId;
  String? cursor;
  bool loading = false;
  bool failed = false;
  bool conflict = false;
  bool _disposed = false;
  int _generation = 0;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool more = false}) async {
    if (more && (loading || cursor == null)) return;
    final generation = ++_generation;
    loading = true;
    failed = false;
    changed();
    try {
      final page = await repository.list(
        cursor: more ? cursor : null,
        search: search,
        recipeId: recipeId,
        clayId: clayId,
      );
      if (generation != _generation || _disposed) return;
      if (!more) {
        final materials = await Future.wait<dynamic>([
          ClayRepository.getClayTypes(),
          GlazeRepository.getGlazes(),
        ]);
        if (generation != _generation || _disposed) return;
        clays = materials[0];
        glazes = materials[1];
        if (repository.tiles) {
          recipes = [];
          String? after;
          do {
            final p = await GlazeNotebookRepository(
              tiles: false,
            ).list(cursor: after);
            if (generation != _generation || _disposed) return;
            recipes.addAll(p.items);
            after = p.nextCursor;
          } while (after != null);
        }
      }
      items = more ? [...items, ...page.items] : page.items;
      for (final r in recipes) {
        recipeNames[r.id] = r.name;
      }
      for (final t in page.items) {
        if (t.sourceCombinationId != null && t.sourceName != null) {
          recipeNames.putIfAbsent(t.sourceCombinationId!, () => t.sourceName!);
        }
      }
      cursor = page.nextCursor;
    } catch (_) {
      if (generation == _generation) failed = true;
    } finally {
      if (generation == _generation) {
        loading = false;
        changed();
      }
    }
  }

  Future<GlazeNotebookDto?> detail(int id) async {
    try {
      return await repository.get(id);
    } catch (_) {
      failed = true;
      changed();
      return null;
    }
  }

  Future<GlazeNotebookDto?> save(GlazeNotebookDto draft) async {
    conflict = false;
    try {
      return await repository.save(draft);
    } catch (e) {
      conflict =
          (e is DioException && e.response?.statusCode == 409) ||
          (e is ApiException && e.statusCode == 409);
      return null;
    }
  }

  Future<bool> delete(GlazeNotebookDto value) async {
    try {
      await repository.delete(value);
      return true;
    } catch (e) {
      conflict =
          (e is DioException && e.response?.statusCode == 409) ||
          (e is ApiException && e.statusCode == 409);
      return false;
    }
  }

  Future<GlazeNotebookDto?> upload(int id, File file) async {
    try {
      await repository.upload(id, file);
      return await repository.get(id);
    } catch (_) {
      return null;
    }
  }

  Future<GlazeNotebookDto?> deleteImage(int id, int imageId) async {
    try {
      await repository.deleteImage(id, imageId);
      return await repository.get(id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
