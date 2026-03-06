part of 'authentication_cubit.dart';

@freezed
class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState.initial() = _Initial;

  const factory AuthenticationState.loading() = _Loading;

  const factory AuthenticationState.authenticated() = _Authenticated;

  const factory AuthenticationState.unauthenticated() = _Unauthenticated;

  const factory AuthenticationState.logout() = _Logout;

  const factory AuthenticationState.error(String message) = _Error;
}