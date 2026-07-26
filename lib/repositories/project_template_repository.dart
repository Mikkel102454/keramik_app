import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/project_template_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class ProjectTemplateRepository {
  static Future<ProjectTemplatePageDto> list({String? cursor}) async {
    final response = await ApiClient.dio.get(
      '/api/project-templates',
      queryParameters: {'cursor': cursor, 'limit': 50},
    );
    checkSuccess(response);
    return ProjectTemplatePageDto.fromJson(response.data['data']);
  }

  static Future<ProjectTemplateDto> create(ProjectTemplateDto template) async {
    final response = await ApiClient.dio.post(
      '/api/project-templates',
      data: template.toRequestJson()..remove('expectedVersion'),
    );
    checkSuccess(response);
    return ProjectTemplateDto.fromJson(response.data['data']);
  }

  static Future<ProjectTemplateDto> update(ProjectTemplateDto template) async {
    final response = await ApiClient.dio.put(
      '/api/project-templates/${template.id}',
      data: template.toRequestJson(),
    );
    checkSuccess(response);
    return ProjectTemplateDto.fromJson(response.data['data']);
  }

  static Future<ProjectTemplateDto> fromCeramic({
    required int ceramicId,
    required String name,
    String? titlePattern,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/project-templates/from-ceramic/$ceramicId',
      data: {'name': name, 'titlePattern': titlePattern},
    );
    checkSuccess(response);
    return ProjectTemplateDto.fromJson(response.data['data']);
  }

  static Future<ProjectTemplateDto> duplicate(
    int templateId,
    String name,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/project-templates/$templateId/duplicate',
      data: {'name': name},
    );
    checkSuccess(response);
    return ProjectTemplateDto.fromJson(response.data['data']);
  }

  static Future<void> delete(int templateId) async {
    final response = await ApiClient.dio.delete(
      '/api/project-templates/$templateId',
    );
    checkSuccess(response);
  }

  static Future<TemplateBatchPreviewDto> preview({
    required int templateId,
    required int quantity,
    required int startNumber,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/project-templates/$templateId/batch-preview',
      data: {
        'quantity': quantity,
        'startNumber': startNumber,
        'expectedVersion': null,
      },
    );
    checkSuccess(response);
    return TemplateBatchPreviewDto.fromJson(response.data['data']);
  }

  static Future<List<String>> createCeramics({
    required int templateId,
    required int quantity,
    required int startNumber,
    required int expectedVersion,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/project-templates/$templateId/ceramics',
      data: {
        'quantity': quantity,
        'startNumber': startNumber,
        'expectedVersion': expectedVersion,
      },
    );
    checkSuccess(response);
    return (response.data['data']['ceramics'] as List)
        .map((value) => value['title'] as String)
        .toList();
  }
}
