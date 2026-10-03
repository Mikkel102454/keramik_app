import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/utils/web.dart';

class PushRepository {
  static Future<bool> available() async {
    final response = await ApiClient.dio.get('/api/account/push');
    checkSuccess(response);
    return response.data['data']['available'] == true;
  }

  static Future<void> register(String id, String token) async {
    final response = await ApiClient.dio.put(
      '/api/account/push/devices/$id',
      data: {'token': token},
    );
    checkSuccess(response);
  }

  static Future<void> remove(String id) async {
    final response = await ApiClient.dio.delete(
      '/api/account/push/devices/$id',
    );
    checkSuccess(response);
  }

  static Future<Map<String, dynamic>> resolve(String event) async {
    final response = await ApiClient.dio.get('/api/account/push/events/$event');
    checkSuccess(response);
    return Map<String, dynamic>.from(response.data['data']);
  }
}
