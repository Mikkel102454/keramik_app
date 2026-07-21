import 'dart:convert';
import 'dart:io';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/image_dto.dart';
import 'package:ceramic_app/utils/file.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ClayRepository {
  static final Map<int, Future<void>> _updateQueues = {};
  static Future<List<ClayDto>> getClayTypes() async {
    final response = await ApiClient.dio.get('/api/clay');

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => ClayDto.fromJson(e)).toList();
  }

  static Future<ClayDto> getClay(int id) async {
    final response = await ApiClient.dio.get('/api/clay/$id');

    checkSuccess(response);

    return ClayDto.fromJson(response.data['data']);
  }

  static Future<void> deleteClay(int id) async {
    final response = await ApiClient.dio.delete('/api/clay/$id');

    checkSuccess(response);
  }

  static Future<void> createClay({
    required ClayDto clay,
    required List<XFile> images,
  }) async {

    final formData = FormData.fromMap({

      'data': MultipartFile.fromString(
        jsonEncode({

          'title': clay.title,
          'supplier': clay.supplier,
          'note': clay.note,
        }),

        contentType: DioMediaType(
          'application',
          'json',
        ),
      ),


      'images': await Future.wait(
        images.map((image) async {

          return MultipartFile.fromFile(
            image.path,
            filename: image.name,
            contentType: DioMediaType('image', 'jpeg'),
          );
        }),
      ),
    });

    final response = await ApiClient.dio.post(
      '/api/clay',
      data: formData,
    );

    checkSuccess(response);
  }

  static Future<void> updateClay({
    required ClayDto clay
  }) async {
    final id = clay.id;
    final payload = <String, dynamic>{
      'title': clay.title,
      'supplier': clay.supplier,
      'note': clay.note,
    };
    final previous = _updateQueues[id] ?? Future<void>.value();
    final request = previous.catchError((_) {}).then((_) async {
      final response = await ApiClient.dio.put('/api/clay/$id', data: payload);
      checkSuccess(response);
    });
    _updateQueues[id] = request;
    try {
      await request;
    } finally {
      if (identical(_updateQueues[id], request)) _updateQueues.remove(id);
    }
  }

  static Future<ImageDto> uploadClayImage({
    required int id,
    required File file,
  }) async {

    final XFile compressed = await compressFile(file);
    try {
      final fileName = compressed.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressed.path,
          filename: fileName,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      final response = await ApiClient.dio.post(
        '/api/clay/$id/image',
        data: formData,
      );
      checkSuccess(response);
      return ImageDto.fromJson(response.data['data']);
    } finally {
      final temporaryFile = File(compressed.path);
      if (await temporaryFile.exists()) await temporaryFile.delete();
    }
  }

  static Future<void> deleteClayImage({
    required ImageDto image
  }) async {
    final response = await ApiClient.dio.delete(
      '/api/clay/${image.objectId}/image/${image.id}',
    );

    checkSuccess(response);
  }
}
