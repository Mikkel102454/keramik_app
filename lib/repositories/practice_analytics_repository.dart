import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/app/app_settings_controller.dart';
import 'package:clay_dock/objects/practice_analytics_dto.dart';
import 'package:clay_dock/utils/web.dart';

class PracticeAnalyticsRepository {
  static Future<PracticeAnalyticsDto> get({
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await ApiClient.dio.get(
      '/api/practice-analytics',
      queryParameters: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        'targetCurrency': AppSettingsController.instance.preferredCurrency,
      },
    );
    checkSuccess(response);
    return PracticeAnalyticsDto.fromJson(response.data['data']);
  }
}
