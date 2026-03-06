import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:kemik_app/config/constants.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  static late Dio dio;
  static late PersistCookieJar cookieJar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage('${dir.path}/cookies'),
    );

    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.appDomain,
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
  }
}