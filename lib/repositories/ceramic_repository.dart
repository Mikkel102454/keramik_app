import 'dart:convert';
import 'dart:io';

import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/image_dto.dart';
import 'package:ceramic_app/utils/file.dart';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CeramicRepository {
  static Future<List<CeramicDto>> getCeramics() async {
    final response = await ApiClient.dio.get('/api/ceramics');

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => CeramicDto.fromJson(e)).toList();
  }

  static Future<CeramicDto> getCeramic(int id) async {
    final response = await ApiClient.dio.get('/api/ceramics/$id');

    checkSuccess(response);

    return CeramicDto.fromJson(response.data['data']);
  }

  static Future<void> deleteCeramic(int id) async {
    final response = await ApiClient.dio.delete('/api/ceramics/$id');

    checkSuccess(response);
  }

  static Future<void> createCeramic({
    required CeramicDto ceramic,
    required List<XFile> images,
  }) async {

    final formData = FormData.fromMap({

      'data': MultipartFile.fromString(
        jsonEncode({

          'title': ceramic.title,
          'clayTypeId': ceramic.clayTypeId,
          'weight': ceramic.weight,
          'note': ceramic.note,
          'rating': ceramic.rating,
          'stageId': ceramic.stageId,

          'tags': ceramic.tags
              .map((e) => e.toJson())
              .toList(),

          'glazes': ceramic.glazes
              .map((e) => e.toJson())
              .toList(),
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
          );
        }),
      ),
    });

    final response = await ApiClient.dio.post(
      '/api/ceramics',
      data: formData,
    );

    checkSuccess(response);
  }

  static Future<void> updateCeramic({
    required CeramicDto ceramic
  }) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/${ceramic.id}',
      data: {
        'title': ceramic.title,
        'clayTypeId': ceramic.clayTypeId,
        'weight': ceramic.weight,
        'note': ceramic.note,
        'rating': ceramic.rating,
        'stageId': ceramic.stageId
      },
    );

    checkSuccess(response);
  }

  static Future<ImageDto> uploadCeramicImage({
    required int ceramicId,
    required File file,
  }) async {

    final XFile compressed = await compressFile(file);

    final fileName =
        compressed.path.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        compressed.path,
        filename: fileName,
      ),
    });

    final response = await ApiClient.dio.post(
      '/api/ceramics/$ceramicId/image',
      data: formData,
    );

    checkSuccess(response);

    return ImageDto.fromJson(
      response.data['data'],
    );
  }

  static Future<void> deleteCeramicImage({
    required ImageDto image
  }) async {
    final response = await ApiClient.dio.delete(
      '/api/ceramics/${image.objectId}/image/${image.id}',
    );

    checkSuccess(response);
  }
}