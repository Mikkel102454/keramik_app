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

  static Future<CeramicGlazeEntryDto> addGlazeNoteEntry(int id, int glazeId, String note) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/$id/glazes',
      data: {
        'glazeId': glazeId,
        'note': note,
      },
    );

    checkSuccess(response);

    return CeramicGlazeEntryDto.fromJson(response.data['data']);
  }

  static Future<CeramicGlazeEntryDto> editGlazeNoteEntry(int id, int noteId, String note) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/glazes/$noteId',
      data: {
        'note': note,
      },
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