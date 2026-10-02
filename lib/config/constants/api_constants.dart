part of 'app_constants.dart';

class ApiConstants {
  const ApiConstants();

  String get membershipUrl => websiteUrl('/membership');
  String get signupUrl => websiteUrl('/signup');
  String get forgotPasswordUrl => websiteUrl('/forgot-password');

  String websiteUrl(String path) {
    const configured = String.fromEnvironment('WEBSITE_BASE_URL');
    final base = configured.isEmpty ? apiDomain : configured;
    final uri = Uri.parse(base);
    if (!uri.hasAuthority ||
        (uri.scheme != 'https' && (kReleaseMode || uri.scheme != 'http'))) {
      throw StateError(
        'Website links require an HTTPS WEBSITE_BASE_URL in release builds',
      );
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
    ).toString();
  }

  String get apiDomain {
    const value = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    if (kReleaseMode && !value.startsWith('https://')) {
      throw StateError('Release builds require an HTTPS API_BASE_URL');
    }
    return value;
  }
}
