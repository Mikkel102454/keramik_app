import 'dart:io';

import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/api/export_download.dart';
import 'package:clay_dock/objects/account_lifecycle_dto.dart';
import 'package:clay_dock/objects/account_settings_dto.dart';
import 'package:clay_dock/objects/user_profile_dto.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:dio/dio.dart';

class AccountRepository {
  static Future<bool> usernameAvailable(String username) async {
    final response = await ApiClient.dio.get(
      '/api/account/username-availability',
      queryParameters: {'username': username},
    );
    checkSuccess(response);
    return response.data['data']['available'] as bool;
  }

  static Future<AccountProfileDto> updateProfile(
    String forename,
    String surname,
    String username,
  ) async {
    final response = await ApiClient.dio.put(
      '/api/account/profile',
      data: {'forename': forename, 'surname': surname, 'username': username},
    );
    checkSuccess(response);
    return AccountProfileDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

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

  static Future<CursorPage<UserProfileDto>> getBlocks({String? cursor}) async {
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

  static Future<File> downloadExport(String id, {CancelToken? cancelToken}) =>
      downloadExportFile(ApiClient.dio, id, cancelToken: cancelToken);

  static Future<AccountDeletionDto> scheduleDeletion({
    required String currentPassword,
    required String confirmation,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/account/deletion',
      data: {'currentPassword': currentPassword, 'confirmation': confirmation},
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
