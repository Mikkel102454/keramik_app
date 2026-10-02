import 'package:url_launcher/url_launcher.dart';

Future<void> openWebPage(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not open $url';
  }
}

String getApiError(dynamic responseData) {
  if (responseData is Map && responseData['error'] is Map) {
    final message = responseData['error']['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
  }
  return 'The server could not complete the request';
}

void checkSuccess(dynamic response) {
  if (response.statusCode == 401) {
    throw ApiException(
      getApiError(response.data),
      statusCode: 401,
      code: _errorCode(response.data),
    );
  }

  final data = response.data;

  if (data == null || data['success'] != true) {
    throw ApiException(
      getApiError(data),
      statusCode: response.statusCode,
      code: _errorCode(data),
      featureKey: data is Map && data['error'] is Map
          ? data['error']['featureKey'] as String?
          : null,
      requiredPlan: data is Map && data['error'] is Map
          ? data['error']['requiredPlan'] as String?
          : null,
      limit: data is Map && data['error'] is Map
          ? (data['error']['limit'] as num?)?.toInt()
          : null,
      currentUsage: data is Map && data['error'] is Map
          ? (data['error']['currentUsage'] as num?)?.toInt()
          : null,
    );
  }
}

String? _errorCode(dynamic data) {
  if (data is Map && data['error'] is Map && data['error']['code'] is String) {
    return data['error']['code'];
  }
  return null;
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.featureKey,
    this.requiredPlan,
    this.limit,
    this.currentUsage,
  });
  final String? featureKey;
  final String? requiredPlan;
  final int? limit;
  final int? currentUsage;
  bool get isSubscriptionError =>
      code == 'SUBSCRIPTION_REQUIRED' || code == 'PLAN_LIMIT_REACHED';
  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}
