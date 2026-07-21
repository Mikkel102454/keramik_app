import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'package:ceramic_app/api/api_client.dart';

part 'authentication_state.dart';
part 'authentication_cubit.freezed.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit({Dio? dio, PersistCookieJar? cookieJar})
      : _dio = dio ?? ApiClient.dio,
        _cookieJar = cookieJar ?? ApiClient.cookieJar,
        super(const AuthenticationState.initial());

  final Dio _dio;
  final PersistCookieJar _cookieJar;

  String _username = '';
  String _password = '';

  void usernameChanged(String value) => _username = value;
  void passwordChanged(String value) => _password = value;

  void sessionExpired() {
    if (!isClosed) emit(const AuthenticationState.unauthenticated());
  }

  Future<void> checkAuthStatus() async {
    try {
      final response = await _dio.get(
        '/api/account/me',
      );

      final data = response.data;
      final authorized = data is Map &&
          (data['authorized'] == true ||
              (data['data'] is Map && data['data']['authorized'] == true));
      if (response.statusCode == 200 && authorized) {
        emit(const AuthenticationState.authenticated());
      } else {
        emit(const AuthenticationState.unauthenticated());
      }
    } catch(e) {
      emit(const AuthenticationState.unauthenticated());
    }
  }

  Future<void> login() async {
    if (_username.isEmpty || _password.isEmpty) {
      emit(const AuthenticationState.error("Please fill all fields"));
      return;
    }

    emit(const AuthenticationState.loading());

    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          "username": _username,
          "password": _password,
          "rememberMe": true,
        },
      );

      if (response.statusCode == 200) {
        emit(const AuthenticationState.authenticated());
      } else if (response.statusCode == 401) {
        emit(const AuthenticationState.error("Invalid credentials"));
      } else {
        emit(const AuthenticationState.error("Server error"));
      }
    } catch (e) {
      emit(const AuthenticationState.error("Network error"));
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
      await _cookieJar.deleteAll();
      emit(const AuthenticationState.logout());
    } catch (e) {
      rethrow;
    }
  }
}
