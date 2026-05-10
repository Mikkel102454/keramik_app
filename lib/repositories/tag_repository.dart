import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class TagRepository {
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

  static Future<void> removeTag(int id, int tagId) async {
    final response = await ApiClient.dio.delete(
      '/api/ceramics/$id/tags/$tagId',
    );

    checkSuccess(response);
  }
}