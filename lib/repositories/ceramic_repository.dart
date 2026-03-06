import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/objects/ceramic_glaze_note_dto.dart';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/utils/web.dart';

class CeramicRepository {
  static Future<List<StageDto>> getStages() async {
    final response = await ApiClient.dio.get('/api/ceramics/stages');

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => StageDto.fromJson(e)).toList();
  }

/* ===================== Ceramics ===================== */

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

  static Future<void> renameCeramic(int id, String title) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/name',
      data: {
        'title': title,
      },
    );

    checkSuccess(response);
  }

  static Future<void> createCeramic({
    required String title,
    required String clayType,
    required double weight,
    required String note,
    required int rating,
    required int stageId,
    required List<String> tags,
    required List<String> glazes,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics',
      data: {
        'title': title,
        'type': clayType,
        'weight': weight,
        'note': note,
        'rate': rating,
        'stage': stageId,
        'tags': tags,
        'glazes': glazes,
      },
    );

    checkSuccess(response);
  }

/* ===================== Progress ===================== */

  static Future<void> setProgress(int id, int stageId) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/stage/$stageId',
    );

    checkSuccess(response);
  }

/* ===================== Properties ===================== */

  static Future<void> setType(int id, String type) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/type',
      data: {
        'type': type,
      },
    );

    checkSuccess(response);
  }

  static Future<void> setWeight(int id, double weight) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/weight',
      data: {
        'weight': weight,
      },
    );

    checkSuccess(response);
  }

  static Future<void> setRate(int id, int rate) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/rate',
      data: {
        'rate': rate,
      },
    );

    checkSuccess(response);
  }

  static Future<void> setNote(int id, String note) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/note',
      data: {
        'note': note,
      },
    );

    checkSuccess(response);
  }

/* ===================== Tags ===================== */

  static Future<List<CeramicTagDto>> getTags(int id) async {
    final response = await ApiClient.dio.get(
      '/api/ceramics/$id/tags',
    );

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => CeramicTagDto.fromJson(e)).toList();
  }

  static Future<CeramicTagDto> addTag(int id, String tag) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/$id/tags',
      data: {
        'tag': tag,
      },
    );

    checkSuccess(response);

    final data = response.data['data'];

    return CeramicTagDto.fromJson(data);
  }

  static Future<CeramicTagDto> editTag(int id, int tagId, String tag) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/tags/$tagId',
      data: {
        'tag': tag,
      },
    );

    checkSuccess(response);

    final data = response.data['data'];

    return CeramicTagDto.fromJson(data);
  }

  static Future<void> removeTag(int id, int tagId) async {
    final response = await ApiClient.dio.delete(
      '/api/ceramics/$id/tags/$tagId',
    );

    checkSuccess(response);
  }

/* ===================== Glaze Notes ===================== */

  static Future<List<CeramicGlazeNoteDto>> getGlazeNotes(int id) async {
    final response = await ApiClient.dio.get(
      '/api/ceramics/$id/glazes',
    );

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => CeramicGlazeNoteDto.fromJson(e)).toList();
  }

  static Future<CeramicGlazeNoteDto> addGlazeNote(int id, String note) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/$id/glazes',
      data: {
        'note': note,
      },
    );

    checkSuccess(response);

    return CeramicGlazeNoteDto.fromJson(response.data['data']);
  }

  static Future<CeramicGlazeNoteDto> editGlazeNote(int id, int noteId, String note) async {
    final response = await ApiClient.dio.put(
      '/api/ceramics/$id/glazes/$noteId',
      data: {
        'note': note,
      },
    );

    checkSuccess(response);

    return CeramicGlazeNoteDto.fromJson(response.data['data']);
  }

  static Future<void> removeGlazeNote(int id, int noteId) async {
    final response = await ApiClient.dio.delete(
      '/api/ceramics/$id/glazes/$noteId',
    );

    checkSuccess(response);
  }
}