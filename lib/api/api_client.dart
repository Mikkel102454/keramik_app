import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:clay_dock/config/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clay_dock/app/client_version_controller.dart';

class ApiClient {
  static late Dio dio;
  static late PersistCookieJar cookieJar;
  static void Function()? onUnauthorized;
  static void Function(Map<String, dynamic> error)? onSubscriptionError;
  static void Function(bool outdated)? onVersionRejected;

  static Future<void> init() async {
    try {
      await InstalledClient.initialize();
    } catch (_) {
      // A missing native identity is unavailable verification, never proof of age.
      InstalledClient.versionCode = null;
      InstalledClient.headers = {};
    }
    final dir = await getApplicationDocumentsDirectory();

    cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage('${dir.path}/cookies'),
    );

    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.api.apiDomain,
        headers: {
          'Content-Type': 'application/json',
          ...InstalledClient.headers,
        },
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),

        // Allow 401 without throwing
        validateStatus: (status) {
          return true;
        },
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.statusCode == 401) onUnauthorized?.call();
          final data = response.data;
          if (data is Map && data['error'] is Map) {
            final error = Map<String, dynamic>.from(data['error']);
            if (error['code'] == 'MFA_REQUIRED' &&
                !response.requestOptions.path.startsWith('/api/auth/mfa/')) {
              onUnauthorized?.call();
            }
            if (error['code'] == 'CLIENT_UPDATE_REQUIRED' ||
                error['code'] == 'CLIENT_VERSION_UNVERIFIED') {
              onVersionRejected?.call(
                error['code'] == 'CLIENT_UPDATE_REQUIRED',
              );
            }
            if (error['code'] == 'SUBSCRIPTION_REQUIRED' ||
                error['code'] == 'PLAN_LIMIT_REACHED') {
              onSubscriptionError?.call(error);
            }
          }
          handler.next(response);
        },
      ),
    );
  }
}
