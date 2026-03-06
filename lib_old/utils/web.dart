import 'package:url_launcher/url_launcher.dart';

Future<void> openWebPage(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not open $url';
  }
}

String getApiError(dynamic responseData) {
  if (responseData is Map &&
      responseData.containsKey('error') &&
      responseData['error'] != null &&
      responseData['error']['message'] != null) {
    return responseData['error']['message'];
  }

  return 'Unknown server error';
}

void checkSuccess(dynamic response) {
  final data = response.data;

  if (data == null || data['success'] != true) {
    throw Exception(getApiError(data));
  }
}