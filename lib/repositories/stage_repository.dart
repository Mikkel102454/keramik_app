import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/stage_dto.dart';
import 'package:clay_dock/utils/web.dart';

class StageRepository {
  static Future<List<StageDto>> getStages() async {
    final response = await ApiClient.dio.get('/api/stages');

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => StageDto.fromJson(e)).toList();
  }
}