import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/ceramic_batch_delete_dto.dart';
import 'package:ceramic_app/objects/ceramic_batch_edit_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class CeramicBatchRepository {
  static Future<CeramicBatchPreviewDto> preview({
    required List<int> ceramicIds,
    required CeramicBatchEditSpec edit,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/batch-edits/preview',
      data: {'ceramicIds': ceramicIds, 'edit': edit.toJson()},
    );
    checkSuccess(response);
    return CeramicBatchPreviewDto.fromJson(response.data['data']);
  }

  static Future<CeramicBatchResultDto> apply({
    required CeramicBatchPreviewDto preview,
    required CeramicBatchEditSpec edit,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/batch-edits',
      data: {
        'targets': preview.targets
            .map(
              (value) => {
                'ceramicId': value.ceramicId,
                'expectedUpdatedAt': value.expectedUpdatedAt.toIso8601String(),
              },
            )
            .toList(),
        'edit': edit.toJson(),
      },
    );
    checkSuccess(response);
    return CeramicBatchResultDto.fromJson(response.data['data']);
  }

  static Future<CeramicBatchDeletePreviewDto> previewDelete(
    List<int> ceramicIds,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/batch-deletions/preview',
      data: {'ceramicIds': ceramicIds},
    );
    checkSuccess(response);
    return CeramicBatchDeletePreviewDto.fromJson(response.data['data']);
  }

  static Future<CeramicBatchDeleteResultDto> applyDelete(
    CeramicBatchDeletePreviewDto preview,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/ceramics/batch-deletions',
      data: {
        'targets': preview.targets
            .map((target) => target.toApplyJson())
            .toList(),
        'confirmation': 'DELETE',
      },
    );
    checkSuccess(response);
    return CeramicBatchDeleteResultDto.fromJson(response.data['data']);
  }
}
