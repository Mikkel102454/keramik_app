import 'dart:typed_data';

import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login sends an email or username through the compatible request field', () async {
    final dio = Dio();
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;
    final cubit = AuthenticationCubit(
      dio: dio,
      cookieJar: PersistCookieJar(),
    );
    addTearDown(cubit.close);

    cubit.identifierChanged('potter@example.com');
    cubit.passwordChanged('password123');
    await cubit.login();

    expect(adapter.request?.path, '/api/auth/login');
    expect(adapter.request?.data, {
      'username': 'potter@example.com',
      'password': 'password123',
      'rememberMe': true,
    });
    expect(cubit.state, const AuthenticationState.authenticated());
  });

  test('failed logout keeps the authenticated state for retry', () async {
    final dio = Dio();
    dio.httpClientAdapter = _RecordingAdapter(failLogout: true);
    final cubit = AuthenticationCubit(
      dio: dio,
      cookieJar: PersistCookieJar(),
    );
    addTearDown(cubit.close);
    cubit.identifierChanged('potter');
    cubit.passwordChanged('password123');
    await cubit.login();

    await expectLater(cubit.logout(), throwsA(isA<Exception>()));
    expect(cubit.state, const AuthenticationState.authenticated());
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.failLogout = false});
  final bool failLogout;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (failLogout && options.path == '/api/auth/logout') {
      return ResponseBody.fromString(
        '{"success":false,"error":{"code":"INTERNAL_ERROR","message":"Retry"}}',
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      '{"success":true,"data":{"username":"potter"}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
