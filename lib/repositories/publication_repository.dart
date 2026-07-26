import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:ceramic_app/utils/web.dart';

class PublicationRepository {
  static Future<PublicationStatusDto> status(int ceramicId) async {
    final response =
        await ApiClient.dio.get('/api/ceramics/$ceramicId/publication');
    checkSuccess(response);
    return PublicationStatusDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<PublicationStatusDto> publish(int ceramicId) async {
    final response =
        await ApiClient.dio.post('/api/ceramics/$ceramicId/publication');
    checkSuccess(response);
    return PublicationStatusDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<PublicationStatusDto> unpublish(int ceramicId) async {
    final response =
        await ApiClient.dio.delete('/api/ceramics/$ceramicId/publication');
    checkSuccess(response);
    return PublicationStatusDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<DiscoverPageDto> discover(
    String mode, {
    String? cursor,
    String? requestId,
  }) async {
    final parameters = <String, dynamic>{
      'mode': mode,
      'limit': 20,
      'requestId': requestId ?? createClientUuid(),
    };
    if (cursor != null) parameters['cursor'] = cursor;
    final response = await ApiClient.dio.get('/api/discover', queryParameters: parameters);
    checkSuccess(response);
    return DiscoverPageDto.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  static Future<PublicationCardDto> like(PublicationCardDto card, bool liked) async {
    final response = liked
        ? await ApiClient.dio.put('/api/discover/${card.publicationId}/like')
        : await ApiClient.dio.delete('/api/discover/${card.publicationId}/like');
    checkSuccess(response);
    final data = response.data['data'] as Map<String, dynamic>;
    return card.copyWith(
      likeCount: (data['likeCount'] as num).toInt(),
      likedByMe: data['likedByMe'] as bool,
    );
  }

  static Future<PublicationDetailDto> detail(String publicationId) async {
    final response =
        await ApiClient.dio.get('/api/discover/$publicationId');
    checkSuccess(response);
    return PublicationDetailDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<void> notInterested(String id, bool hidden) async {
    final response = hidden
        ? await ApiClient.dio.put('/api/discover/$id/not-interested')
        : await ApiClient.dio.delete('/api/discover/$id/not-interested');
    checkSuccess(response);
  }

  static Future<void> report(
    String id,
    String category,
    String explanation,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/discover/$id/reports',
      data: {
        'clientReportId': createClientUuid(),
        'category': category,
        'explanation': explanation.trim(),
      },
    );
    checkSuccess(response);
  }
}
