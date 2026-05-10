import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class StageRepository {
  static Future<List<StageDto>> getStages() async {
    final response = await ApiClient.dio.get('/api/stages');

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => StageDto.fromJson(e)).toList();
  }
}