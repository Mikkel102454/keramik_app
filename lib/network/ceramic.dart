import 'package:kemik_app/classes/ceramic_dto.dart';
import 'package:kemik_app/classes/ceramic_tag_dto.dart';
import 'package:kemik_app/classes/stage_dto.dart';

import '../api/api_client.dart';
import '../classes/cemaric_glaze_note_dto.dart';
import '../utils/web.dart';

/* ===================== Stages ===================== */

Future<List<StageDto>> getStages() async {
  final response = await ApiClient.dio.get('/api/ceramics/stages');

  checkSuccess(response);

  final list = response.data['data'] as List;

  return list.map((e) => StageDto.fromJson(e)).toList();
}

/* ===================== Ceramics ===================== */

Future<List<CeramicDto>> getCeramics() async {
  final response = await ApiClient.dio.get('/api/ceramics');

  checkSuccess(response);

  final list = response.data['data'] as List;

  return list.map((e) => CeramicDto.fromJson(e)).toList();
}

Future<void> deleteCeramic(int id) async {
  final response = await ApiClient.dio.delete('/api/ceramics/$id');

  checkSuccess(response);
}

Future<void> renameCeramic(int id, String title) async {
  final response = await ApiClient.dio.put(
    '/api/ceramics/$id/name',
    data: {
      'title': title,
    },
  );

  checkSuccess(response);
}

Future<void> createCeramic({
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

Future<void> setProgress(int id, int stageId) async {
  final response = await ApiClient.dio.put(
    '/api/ceramics/$id/stage/$stageId',
  );

  checkSuccess(response);
}

/* ===================== Properties ===================== */

Future<void> setType(int id, String type) async {
  final response = await ApiClient.dio.put(
    '/api/ceramics/$id/type',
    data: {
      'type': type,
    },
  );

  checkSuccess(response);
}

Future<void> setWeight(int id, double weight) async {
  final response = await ApiClient.dio.put(
    '/api/ceramics/$id/weight',
    data: {
      'weight': weight,
    },
  );

  checkSuccess(response);
}

Future<void> setRate(int id, int rate) async {
  final response = await ApiClient.dio.put(
    '/api/ceramics/$id/rate',
    data: {
      'rate': rate,
    },
  );

  checkSuccess(response);
}

Future<void> setNote(int id, String note) async {
  final response = await ApiClient.dio.put(
    '/api/ceramics/$id/note',
    data: {
      'note': note,
    },
  );

  checkSuccess(response);
}

/* ===================== Tags ===================== */

Future<List<CeramicTagDto>> getTags(int id) async {
  final response = await ApiClient.dio.get(
    '/api/ceramics/$id/tags',
  );

  checkSuccess(response);

  final list = response.data['data'] as List;

  return list.map((e) => CeramicTagDto.fromJson(e)).toList();
}

Future<void> addTag(int id, String tag) async {
  final response = await ApiClient.dio.post(
    '/api/ceramics/$id/tags',
    data: {
      'tag': tag,
    },
  );

  checkSuccess(response);
}

Future<void> editTag(int id, int tagId, String tag) async {
  final response = await ApiClient.dio.put(
    '/api/ceramics/$id/tags/$tagId',
    data: {
      'tag': tag,
    },
  );

  checkSuccess(response);
}

Future<void> removeTag(int id, int tagId) async {
  final response = await ApiClient.dio.delete(
    '/api/ceramics/$id/tags/$tagId',
  );

  checkSuccess(response);
}

/* ===================== Glaze Notes ===================== */

Future<List<CeramicGlazeNoteDto>> getGlazeNotes(int id) async {
  final response = await ApiClient.dio.get(
    '/api/ceramics/$id/glazes',
  );

  checkSuccess(response);

  final list = response.data['data'] as List;

  return list.map((e) => CeramicGlazeNoteDto.fromJson(e)).toList();
}

Future<void> addGlazeNote(int id, String note) async {
  final response = await ApiClient.dio.post(
    '/api/ceramics/$id/glazes',
    data: {
      'note': note,
    },
  );

  checkSuccess(response);
}

Future<void> editGlazeNote(int id, int noteId, String note) async {
  final response = await ApiClient.dio.put(
    '/api/ceramics/$id/glazes/$noteId',
    data: {
      'note': note,
    },
  );

  checkSuccess(response);
}

Future<void> removeGlazeNote(int id, int noteId) async {
  final response = await ApiClient.dio.delete(
    '/api/ceramics/$id/glazes/$noteId',
  );

  checkSuccess(response);
}