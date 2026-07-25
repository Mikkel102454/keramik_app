import 'dart:io';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/account_lifecycle_dto.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AccountRepository {
  static Future<AccountSettingsDto> getSettings() async {
    final response = await ApiClient.dio.get('/api/account/settings');
    checkSuccess(response);
    return AccountSettingsDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<AccountSettingsDto> updateSettings(
    AccountSettingsDto settings,
  ) async {
    final response = await ApiClient.dio.put(
      '/api/account/settings',
      data: settings.toJson(),
    );
    checkSuccess(response);
    return AccountSettingsDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final response = await ApiClient.dio.put(
      '/api/account/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmation': confirmation,
      },
    );
    checkSuccess(response);
  }

  static Future<CursorPage<UserProfileDto>> getBlocks({
    String? cursor,
  }) async {
    final query = <String, dynamic>{'limit': 20};
    if (cursor case final value?) query['cursor'] = value;
    final response = await ApiClient.dio.get(
      '/api/blocks',
      queryParameters: query,
    );
    checkSuccess(response);
    return CursorPage.fromJson(
      response.data['data'] as Map<String, dynamic>,
      UserProfileDto.fromJson,
    );
  }

  static Future<DataExportDto> createExport() async {
    final response = await ApiClient.dio.post('/api/account/exports');
    checkSuccess(response);
    return DataExportDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<DataExportDto> getExport(String id) async {
    final response = await ApiClient.dio.get('/api/account/exports/$id');
    checkSuccess(response);
    return DataExportDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<File> downloadExport(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/keramik-data-$id.zip');
    final response = await ApiClient.dio.get<List<int>>(
      '/api/account/exports/$id/download',
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const ApiException('The export could not be downloaded');
    }
    await file.writeAsBytes(response.data!, flush: true);
    return file;
  }

  static Future<AccountDeletionDto> scheduleDeletion({
    required String currentPassword,
    required String confirmation,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/account/deletion',
      data: {
        'currentPassword': currentPassword,
        'confirmation': confirmation,
      },
    );
    checkSuccess(response);
    return AccountDeletionDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<AccountDeletionDto> cancelDeletion() async {
    final response = await ApiClient.dio.delete('/api/account/deletion');
    checkSuccess(response);
    return AccountDeletionDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
