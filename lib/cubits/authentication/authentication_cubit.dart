import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:ceramic_app/repositories/account_repository.dart';

part 'authentication_state.dart';
part 'authentication_cubit.freezed.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit({Dio? dio, PersistCookieJar? cookieJar})
      : _dio = dio ?? ApiClient.dio,
        _cookieJar = cookieJar ?? ApiClient.cookieJar,
        super(const AuthenticationState.initial());

  final Dio _dio;
  final PersistCookieJar _cookieJar;

  String _identifier = '';
  String _password = '';
  bool deletionPending = false;

  void identifierChanged(String value) => _identifier = value;
  void passwordChanged(String value) => _password = value;

  void sessionExpired() {
    deletionPending = false;
    if (!isClosed) emit(const AuthenticationState.unauthenticated());
  }

  Future<void> checkAuthStatus() async {
    try {
      final response = await _dio.get(
        '/api/account/me',
      );

      checkSuccess(response);
      final data = response.data;
      final authorized = data is Map && data['data'] is Map &&
          data['data']['authorized'] == true;
      deletionPending = data is Map &&
          data['data'] is Map &&
          data['data']['deletionPending'] == true;
      if (response.statusCode == 200 && authorized) {
        if (deletionPending) {
          emit(const AuthenticationState.error(
            'Account deletion is pending. Cancel deletion or sign out.',
          ));
        } else {
          emit(const AuthenticationState.authenticated());
        }
      } else {
        emit(const AuthenticationState.unauthenticated());
      }
    } catch(e) {
      emit(const AuthenticationState.unauthenticated());
    }
  }

  Future<void> login() async {
    if (_identifier.isEmpty || _password.isEmpty) {
      emit(const AuthenticationState.error("Please fill all fields"));
      return;
    }

    emit(const AuthenticationState.loading());

    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          // Keep the established API field name for backward compatibility.
          "username": _identifier,
          "password": _password,
          "rememberMe": true,
        },
      );

      checkSuccess(response);
      if (response.statusCode == 200) {
        deletionPending = response.data is Map &&
            response.data['data'] is Map &&
            response.data['data']['deletionPending'] == true;
        if (deletionPending) {
          emit(const AuthenticationState.error(
            'Account deletion is pending. Cancel deletion or sign out.',
          ));
        } else {
          emit(const AuthenticationState.authenticated());
        }
      } else if (response.statusCode == 401) {
        emit(const AuthenticationState.error("Invalid credentials"));
      } else {
        emit(const AuthenticationState.error("Server error"));
      }
    } on ApiException catch (e) {
      emit(AuthenticationState.error(authenticationErrorMessage(e)));
    } catch (e) {
      emit(const AuthenticationState.error("Network error"));
    }
  }

  Future<void> logout() async {
    try {
      final response = await _dio.post('/api/auth/logout');
      checkSuccess(response);
      await _cookieJar.deleteAll();
      deletionPending = false;
      emit(const AuthenticationState.unauthenticated());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelDeletion() async {
    emit(const AuthenticationState.loading());
    try {
      await AccountRepository.cancelDeletion();
      deletionPending = false;
      emit(const AuthenticationState.authenticated());
    } on ApiException catch (error) {
      emit(AuthenticationState.error(error.message));
    } catch (_) {
      emit(const AuthenticationState.error(
        'Deletion could not be canceled. Please retry.',
      ));
    }
  }

  Future<void> signOutPendingDeletion() => logout();
}

String authenticationErrorMessage(ApiException exception) {
  if (exception.code == 'PASSWORD_CHANGE_REQUIRED') {
    return 'Change your temporary password on the Keramik website before signing in.';
  }
  if (exception.statusCode == 401) return 'Invalid credentials';
  return 'Server error';
}
