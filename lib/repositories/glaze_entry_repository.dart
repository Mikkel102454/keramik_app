import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class GlazeEntryRepository {
  static Future<List<CeramicGlazeEntryDto>> getGlazeNoteEntries(int id) async {
    final response = await ApiClient.dio.get(
      '/api/ceramics/$id/glazes',
    );

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => CeramicGlazeEntryDto.fromJson(e)).toList();
  }

  static Future<CeramicGlazeEntryDto> addGlazeNoteEntry(
    int id,
    int glazeId,
    String note, {
    required int layerOrder,
    required int coatCount,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/$id/glazes',
      data: {
        'glazeId': glazeId,
        'note': note,
        'layerOrder': layerOrder,
        'coatCount': coatCount,
      },
    );

    checkSuccess(response);

    return CeramicGlazeEntryDto.fromJson(response.data['data']);
  }

  static Future<CeramicGlazeEntryDto> editGlazeNoteEntry(
    int id,
    int noteId, {
    String? note,
    int? layerOrder,
    int? coatCount,
  }) async {
    final payload = <String, dynamic>{};
    if (note != null) payload['note'] = note;
    if (layerOrder != null) payload['layerOrder'] = layerOrder;
    if (coatCount != null) payload['coatCount'] = coatCount;
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/glazes/$noteId',
      data: payload,
    );

    checkSuccess(response);

    return CeramicGlazeEntryDto.fromJson(response.data['data']);
  }

  static Future<void> removeGlazeNoteEntry(int id, int noteId) async {
    final response = await ApiClient.dio.delete(
      '/api/ceramics/$id/glazes/$noteId',
    );

    checkSuccess(response);
  }
}
