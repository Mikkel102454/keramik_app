import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:ceramic_app/config/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  static late Dio dio;
  static late PersistCookieJar cookieJar;
  static void Function()? onUnauthorized;

  static Future<void> init() async {
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
        },

        // Allow 401 without throwing
        validateStatus: (status) {
          return true;
        },
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(InterceptorsWrapper(onResponse: (response, handler) {
      if (response.statusCode == 401) onUnauthorized?.call();
      handler.next(response);
    }));
  }
}
