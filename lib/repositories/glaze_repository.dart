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
}