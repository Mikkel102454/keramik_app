import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class GlazeRepository {
  static Future<List<GlazeDto>> getGlazes() async {
    final response = await ApiClient.dio.get('/api/glaze');

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => GlazeDto.fromJson(e)).toList();
  }

  static Future<GlazeDto> getGlaze(int id) async {
    final response = await ApiClient.dio.get('/api/glaze/$id');
    checkSuccess(response);
    return GlazeDto.fromJson(response.data['data']);
  }

  static Future<void> createGlaze(String title) async {
    final response = await ApiClient.dio.post(
      '/api/glaze',
      data: {'title': title},
    );
    checkSuccess(response);
  }

  static Future<void> updateGlaze(GlazeDto glaze) async {
    final response = await ApiClient.dio.put(
      '/api/glaze/${glaze.id}',
      data: {'title': glaze.title},
    );
    checkSuccess(response);
  }

  static Future<void> deleteGlaze(int id) async {
    final response = await ApiClient.dio.delete('/api/glaze/$id');
    checkSuccess(response);
  }
}
