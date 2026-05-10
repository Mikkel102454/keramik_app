import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class ClayRepository {
  static Future<List<ClayDto>> getClayTypes() async {
    final response = await ApiClient.dio.get('/api/clay');

    checkSuccess(response);

    final list = response.data['data'] as List;

    return list.map((e) => ClayDto.fromJson(e)).toList();
  }
}