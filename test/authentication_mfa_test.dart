import 'dart:convert';
import 'dart:typed_data';
import 'package:clay_dock/cubits/authentication/authentication_cubit.dart';
import 'package:clay_dock/repositories/mfa_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'password challenge never grants app access until recovery or TOTP succeeds',
    () async {
      final adapter = _MfaAdapter();
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = adapter;
      final cubit = AuthenticationCubit(
        dio: dio,
        cookieJar: PersistCookieJar(persistSession: false),
      );
      addTearDown(cubit.close);
      cubit.identifierChanged('member');
      cubit.passwordChanged('password');
      await cubit.login();
      expect(cubit.mfaRequired, isTrue);
      expect(cubit.mfaEnrollmentRequired, isFalse);
      expect(cubit.state, const AuthenticationState.unauthenticated());
      adapter.reject = true;
      await cubit.verifyMfa('invalid');
      expect(cubit.mfaRequired, isTrue);
      expect(
        cubit.state,
        const AuthenticationState.error('Invalid or already used code'),
      );
      adapter.reject = false;
      await cubit.verifyMfa('123456');
      expect(adapter.last?.path, '/api/auth/mfa/verify');
      expect(adapter.last?.data, {'code': '123456'});
      expect(cubit.mfaRequired, isFalse);
      expect(cubit.state, const AuthenticationState.authenticated());
    },
  );
  test(
    'administrator enrollment and account switching keep the password challenge isolated',
    () async {
      final adapter = _MfaAdapter()..enrollment = true;
      final dio = Dio()..httpClientAdapter = adapter;
      final cubit = AuthenticationCubit(
        dio: dio,
        cookieJar: PersistCookieJar(persistSession: false),
      );
      addTearDown(cubit.close);
      cubit.identifierChanged('admin');
      cubit.passwordChanged('password');
      await cubit.login();
      expect(cubit.mfaEnrollmentRequired, isTrue);
      cubit.cancelMfa();
      expect(cubit.mfaRequired, isFalse);
      await cubit.login();
      expect(
        cubit.state,
        const AuthenticationState.error('Please fill all fields'),
      );
    },
  );
  test(
    'factor-management consumer preserves coordinated body and recovery-code contract',
    () async {
      final adapter = _MfaAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = MfaRepository(dio: dio);
      expect(
        await repository.regenerate('current-password', ' recovery-code '),
        ['one-time-code'],
      );
      expect(adapter.last?.path, '/api/auth/mfa/recovery-codes');
      expect(adapter.last?.data, {
        'password': 'current-password',
        'code': 'recovery-code',
      });
    },
  );
}

class _MfaAdapter implements HttpClientAdapter {
  bool reject = false;
  bool enrollment = false;
  RequestOptions? last;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    final Map<String, dynamic> response;
    if (options.path == '/api/auth/login') {
      response = {
        'success': true,
        'data': {'mfaRequired': true, 'enrollmentRequired': enrollment},
      };
    } else if (options.path.endsWith('recovery-codes')) {
      response = {
        'success': true,
        'data': {
          'recoveryCodes': ['one-time-code'],
        },
      };
    } else if (reject) {
      response = {
        'success': false,
        'error': {
          'code': 'MFA_REQUIRED',
          'message': 'Invalid or already used code',
        },
      };
    } else {
      response = {
        'success': true,
        'data': {'username': 'member', 'deletionPending': false},
      };
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      reject ? 403 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
