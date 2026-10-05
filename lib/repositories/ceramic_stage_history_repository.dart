import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/ceramic_stage_history_dto.dart';
import 'package:clay_dock/utils/web.dart';

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
