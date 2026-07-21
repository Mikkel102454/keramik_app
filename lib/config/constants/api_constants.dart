part of 'app_constants.dart';

class ApiConstants {
  const ApiConstants();

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
