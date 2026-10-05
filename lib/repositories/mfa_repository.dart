import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:dio/dio.dart';

class MfaRepository {
  MfaRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<Map<String, dynamic>> status() async {
    final response = await _dio.get('/api/auth/mfa/status');
    checkSuccess(response);
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> enroll(String password) =>
      _post('enroll', password: password);
  Future<Map<String, dynamic>> replace(String password, String code) =>
      _post('replace', password: password, code: code);
  Future<List<String>> confirm(String code) async =>
      _codes(await _post('confirm', code: code));
  Future<List<String>> regenerate(String password, String code) async =>
      _codes(await _post('recovery-codes', password: password, code: code));
  Future<void> disable(String password, String code) async {
    await _post('disable', password: password, code: code);
  }

  Future<Map<String, dynamic>> _post(
    String action, {
    String? password,
    String? code,
  }) async {
    final response = await _dio.post(
      '/api/auth/mfa/$action',
      data: {'password': ?password, 'code': ?code?.trim()},
    );
    checkSuccess(response);
    return response.data['data'] is Map
        ? Map<String, dynamic>.from(response.data['data'] as Map)
        : <String, dynamic>{};
  }

  static List<String> _codes(Map<String, dynamic> data) =>
      (data['recoveryCodes'] as List).cast<String>();
}
