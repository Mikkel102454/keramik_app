import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/glaze_notebook_dto.dart';
import 'package:ceramic_app/objects/image_dto.dart';
import 'package:ceramic_app/utils/file.dart';
import 'package:ceramic_app/utils/web.dart';

class GlazeNotebookRepository {
  GlazeNotebookRepository({required this.tiles});
  final bool tiles;
  String get path => tiles ? '/api/test-tiles' : '/api/glaze-combinations';
  Future<NotebookPageDto> list({
    String? cursor,
    String search = '',
    int? recipeId,
    int? clayId,
  }) async {
    final r = await ApiClient.dio.get(
      path,
      queryParameters: {
        'cursor': ?cursor,
        'limit': 50,
        'search': search,
        'recipeId': ?recipeId,
        'clayId': ?clayId,
      },
    );
    checkSuccess(r);
    return NotebookPageDto.fromJson(r.data['data']);
  }

  Future<GlazeNotebookDto> get(int id) async {
    final r = await ApiClient.dio.get('$path/$id');
    checkSuccess(r);
    return GlazeNotebookDto.fromJson(r.data['data']);
  }

  Future<GlazeNotebookDto> save(GlazeNotebookDto value) async {
    final r = value.id == 0
        ? await ApiClient.dio.post(path, data: value.toRequestJson())
        : await ApiClient.dio.put(
            '$path/${value.id}',
            data: value.toRequestJson(),
          );
    checkSuccess(r);
    return GlazeNotebookDto.fromJson(r.data['data']);
  }

  Future<void> delete(GlazeNotebookDto value) async {
    final r = await ApiClient.dio.delete(
      '$path/${value.id}',
      queryParameters: {'expectedVersion': value.version},
    );
    checkSuccess(r);
  }

  Future<List<ImageDto>> upload(int id, File file) async {
    final compressed = await compressFile(file);
    try {
      final r = await ApiClient.dio.post(
        '$path/$id/images',
        data: FormData.fromMap({
          'files': [
            await MultipartFile.fromFile(
              compressed.path,
              filename: 'tile.jpg',
              contentType: DioMediaType('image', 'jpeg'),
            ),
          ],
        }),
      );
      checkSuccess(r);
      return (r.data['data'] as List).map((i) => ImageDto.fromJson(i)).toList();
    } finally {
      final temp = File(compressed.path);
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<void> deleteImage(int id, int imageId) async {
    final r = await ApiClient.dio.delete('$path/$id/images/$imageId');
    checkSuccess(r);
  }

  static Future<void> apply(
    int pieceId,
    int combinationId,
    int version,
    String requestId,
  ) async {
    final r = await ApiClient.dio.post(
      '/api/ceramics/$pieceId/glaze-combinations/$combinationId/apply',
      data: {
        'clientRequestId': requestId,
        'expectedCombinationVersion': version,
      },
    );
    checkSuccess(r);
  }
}
