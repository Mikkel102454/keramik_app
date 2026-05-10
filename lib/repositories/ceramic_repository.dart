import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/utils/web.dart';

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
    required CeramicDto ceramic
  }) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics',
      data: {
        'title': ceramic.title,
        'clayTypeId': ceramic.clayTypeId,
        'weight': ceramic.weight,
        'note': ceramic.note,
        'rating': ceramic.rating,
        'stageId': ceramic.stageId,
        'tags': ceramic.tags,
        'glazes': ceramic.glazes,
      },
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
}