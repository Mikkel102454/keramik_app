import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/ceramic_stage_history_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class CeramicStageHistoryRepository {
  static Future<List<CeramicStageHistoryDto>> getHistory(int ceramicId) async {
    final response = await ApiClient.dio.get(
      '/api/ceramics/$ceramicId/stage-history',
    );
    checkSuccess(response);
    return (response.data['data'] as List)
        .map((json) => CeramicStageHistoryDto.fromJson(json))
        .toList();
  }
}
