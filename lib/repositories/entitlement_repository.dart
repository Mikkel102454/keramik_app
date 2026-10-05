import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/entitlement_dto.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:dio/dio.dart';

class EntitlementRepository {
  static Future<EntitlementDto> load() async {
    final response = await ApiClient.dio.get(
      '/api/account/entitlements',
      options: Options(
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    checkSuccess(response);
    return EntitlementDto.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }
}
