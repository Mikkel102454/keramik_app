import 'package:clay_dock/app/chat_media_controller.dart';
import 'package:clay_dock/app/push_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:clay_dock/utils/network_timeout.dart';
import 'package:clay_dock/repositories/account_repository.dart';
import 'package:clay_dock/app/combination_application_controller.dart';

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
  bool mfaRequired = false;
  bool mfaEnrollmentRequired = false;
  static const loginThrottledMessage = 'RATE_LIMITED';
  static const requestTimedOutMessage = 'REQUEST_TIMED_OUT';
  int? loginRetryAfterSeconds;

  void identifierChanged(String value) => _identifier = value;
  void passwordChanged(String value) => _password = value;

  void sessionExpired() {
    CombinationApplicationController.clearSession();
    deletionPending = false;
    mfaRequired = false;
    mfaEnrollmentRequired = false;
    _password = '';
    if (!isClosed) emit(const AuthenticationState.unauthenticated());
  }

  Future<void> checkAuthStatus() async {
    try {
      final response = await _dio.get('/api/account/me');

      checkSuccess(response);
      final data = response.data;
      final authorized =
          data is Map &&
          data['data'] is Map &&
          data['data']['authorized'] == true;
      deletionPending =
          data is Map &&
          data['data'] is Map &&
          data['data']['deletionPending'] == true;
      if (response.statusCode == 200 && authorized) {
        if (deletionPending) {
          emit(
            const AuthenticationState.error(
              'Account deletion is pending. Cancel deletion or sign out.',
            ),
          );
        } else {
          emit(const AuthenticationState.authenticated());
        }
      } else {
        emit(const AuthenticationState.unauthenticated());
      }
    } on DioException catch (e) {
      // No response is not proof of session expiry. Retain an authenticated
      // session; at startup expose recoverable feedback without clearing cookies.
      if (isNetworkTimeout(e) || e.response == null) {
        if (state != const AuthenticationState.authenticated()) {
          emit(
            AuthenticationState.error(
              isNetworkTimeout(e) ? requestTimedOutMessage : 'Network error',
            ),
          );
        }
      } else {
        emit(const AuthenticationState.unauthenticated());
      }
    } catch (e) {
      emit(const AuthenticationState.unauthenticated());
    }
  }

  Future<void> login() async {
    loginRetryAfterSeconds = null;
    mfaRequired = false;
    mfaEnrollmentRequired = false;
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

      if (response.statusCode == 429) {
        _loginThrottled(response);
        return;
      }
      checkSuccess(response);
      if (response.statusCode == 200) {
        final payload = response.data is Map ? response.data['data'] : null;
        if (payload is Map && payload['mfaRequired'] == true) {
          mfaRequired = true;
          mfaEnrollmentRequired = payload['enrollmentRequired'] == true;
          _password = '';
          emit(const AuthenticationState.unauthenticated());
          return;
        }
        _password = '';
        deletionPending =
            response.data is Map &&
            response.data['data'] is Map &&
            response.data['data']['deletionPending'] == true;
        if (deletionPending) {
          emit(
            const AuthenticationState.error(
              'Account deletion is pending. Cancel deletion or sign out.',
            ),
          );
        } else {
          emit(const AuthenticationState.authenticated());
        }
      } else if (response.statusCode == 401) {
        emit(const AuthenticationState.error("Invalid credentials"));
      } else {
        emit(const AuthenticationState.error("Server error"));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        _loginThrottled(e.response!);
      } else if (isNetworkTimeout(e)) {
        emit(const AuthenticationState.error(requestTimedOutMessage));
      } else {
        emit(const AuthenticationState.error("Network error"));
      }
    } on ApiException catch (e) {
      emit(AuthenticationState.error(authenticationErrorMessage(e)));
    } catch (e) {
      emit(const AuthenticationState.error("Network error"));
    }
  }

  Future<void> verifyMfa(String code) async {
    emit(const AuthenticationState.loading());
    try {
      final response = await _dio.post(
        '/api/auth/mfa/verify',
        data: {'code': code.trim()},
      );
      checkSuccess(response);
      mfaRequired = false;
      mfaEnrollmentRequired = false;
      deletionPending =
          response.data is Map &&
          response.data['data'] is Map &&
          response.data['data']['deletionPending'] == true;
      if (deletionPending) {
        emit(
          const AuthenticationState.error(
            'Account deletion is pending. Cancel deletion or sign out.',
          ),
        );
      } else {
        emit(const AuthenticationState.authenticated());
      }
    } on ApiException catch (error) {
      emit(AuthenticationState.error(error.message));
    } catch (_) {
      emit(const AuthenticationState.error('Network error'));
    }
  }

  Future<void> completeMfaEnrollment() async {
    mfaRequired = false;
    mfaEnrollmentRequired = false;
    await checkAuthStatus();
  }

  void cancelMfa() {
    mfaRequired = false;
    mfaEnrollmentRequired = false;
    _password = '';
    emit(const AuthenticationState.initial());
  }

  void _loginThrottled(Response<dynamic> response) {
    final seconds = int.tryParse(response.headers.value('retry-after') ?? '');
    loginRetryAfterSeconds = seconds != null && seconds > 0 ? seconds : null;
    emit(const AuthenticationState.error(loginThrottledMessage));
  }

  Future<void> logout() async {
    try {
      await PushController.instance.logout();
      final response = await _dio.post('/api/auth/logout');
      checkSuccess(response);
      await _cookieJar.deleteAll();
      await ChatMediaDownload.clear();
      CombinationApplicationController.clearSession();
      deletionPending = false;
      mfaRequired = false;
      mfaEnrollmentRequired = false;
      _password = '';
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
      emit(
        const AuthenticationState.error(
          'Deletion could not be canceled. Please retry.',
        ),
      );
    }
  }

  Future<void> signOutPendingDeletion() => logout();
}

String authenticationErrorMessage(ApiException exception) {
  if (exception.code == 'PASSWORD_CHANGE_REQUIRED') {
    return 'Change your temporary password on the ClayDock website before signing in.';
  }
  if (exception.statusCode == 401) return 'Invalid credentials';
  return 'Server error';
}
