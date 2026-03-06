import 'dart:convert';

import '../api/api_client.dart';

Future<bool> loginRequest(String username, String password) async {
  try {
    final response = await ApiClient.dio.post(
      '/api/auth/login',
      data: {
        "username": username,
        "password": password,
        'rememberMe': true,
      },
    );


    if (response.statusCode == 200) {
      // Login success
      return true;
    } else {
      // Login failed
      return false;
    }

  } catch (e) {
    return false;
  }
}

Future<bool> logoutRequest() async {
  try {
    final response = await ApiClient.dio.post('/api/auth/logout');
    await ApiClient.cookieJar.deleteAll();
    return true;
  } catch (e) {
    rethrow;
  }
}

Future<bool> fetchUserMe() async {
  try {
    final response = await ApiClient.dio.get(
      '/api/account/me',
    );

    if(response.data["authorized"]){
      return true;
    }
    return false;
  } catch(e) {
    return false;
  }
}