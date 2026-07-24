import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/ceramic_firing_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class CeramicFiringRepository {
  static Future<List<CeramicFiringDto>> getFirings(int ceramicId) async {
    final response = await ApiClient.dio.get('/api/ceramics/$ceramicId/firings');
    checkSuccess(response);
    return (response.data['data'] as List)
        .map((json) => CeramicFiringDto.fromJson(json))
        .toList();
  }

  static Future<CeramicFiringDto> create(
    int ceramicId,
    CeramicFiringDto firing,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/$ceramicId/firings',
      data: firing.toRequestJson(),
    );
    checkSuccess(response);
    return CeramicFiringDto.fromJson(response.data['data']);
  }

  static Future<CeramicFiringDto> update(
    int ceramicId,
    CeramicFiringDto firing,
  ) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$ceramicId/firings/${firing.id}',
      data: firing.toRequestJson(),
    );
    checkSuccess(response);
    return CeramicFiringDto.fromJson(response.data['data']);
  }

  static Future<void> delete(int ceramicId, int firingId) async {
    final response = await ApiClient.dio.delete(
      '/api/ceramics/$ceramicId/firings/$firingId',
    );
    checkSuccess(response);
  }
}
