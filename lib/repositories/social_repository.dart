import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/objects/public_ceramic_card_dto.dart';
import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class SocialRepository {
  static Future<AccountProfileDto> getMe() async {
    final response = await ApiClient.dio.get('/api/account/me');
    checkSuccess(response);
    return AccountProfileDto.fromJson(response.data['data']);
  }

  static Future<CursorPage<UserProfileDto>> search(
    String query, {
    String? cursor,
  }) async {
    final queryParameters = <String, dynamic>{'q': query, 'limit': 20};
    if (cursor case final value?) queryParameters['cursor'] = value;
    final response = await ApiClient.dio.get(
      '/api/users/search',
      queryParameters: queryParameters,
    );
    checkSuccess(response);
    return CursorPage.fromJson(response.data['data'], UserProfileDto.fromJson);
  }

  static Future<UserProfileDto> getProfile(String userId) async {
    final response = await ApiClient.dio.get('/api/users/$userId');
    checkSuccess(response);
    return UserProfileDto.fromJson(response.data['data']);
  }

  static Future<List<PublicCeramicCardDto>> getFinishedCeramics(
    String userId,
  ) async {
    final response = await ApiClient.dio.get(
      '/api/users/$userId/finished-ceramics',
    );
    checkSuccess(response);
    return (response.data['data'] as List)
        .map(
          (item) => PublicCeramicCardDto.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<List<PublicCeramicCardDto>> getPublishedCeramics(
    String userId,
  ) async {
    final response = await ApiClient.dio.get('/api/users/$userId/publications');
    checkSuccess(response);
    return (response.data['data'] as List)
        .map((item) => PublicationCardDto.fromJson(item as Map<String, dynamic>))
        .map(
          (item) => PublicCeramicCardDto(
            publicationId: item.publicationId,
            imageUrl: item.primaryImage?.uri,
            title: item.title,
            stage: 'Finished',
            clayTitle: item.clay,
            rating: 0,
            likeCount: item.likeCount,
          ),
        )
        .toList();
  }

  static Future<CursorPage<UserProfileDto>> getFriends({String? cursor}) async {
    final queryParameters = <String, dynamic>{'limit': 20};
    if (cursor case final value?) queryParameters['cursor'] = value;
    final response = await ApiClient.dio.get(
      '/api/friends',
      queryParameters: queryParameters,
    );
    checkSuccess(response);
    return CursorPage.fromJson(response.data['data'], UserProfileDto.fromJson);
  }

  static Future<CursorPage<FriendRequestDto>> getRequests(
    String direction, {
    String? cursor,
  }) async {
    final queryParameters = <String, dynamic>{'direction': direction, 'limit': 20};
    if (cursor case final value?) queryParameters['cursor'] = value;
    final response = await ApiClient.dio.get(
      '/api/friend-requests',
      queryParameters: queryParameters,
    );
    checkSuccess(response);
    return CursorPage.fromJson(response.data['data'], FriendRequestDto.fromJson);
  }

  static Future<UserProfileDto> sendFriendRequest(String userId) async {
    final response = await ApiClient.dio.post('/api/friend-requests', data: {'userId': userId});
    checkSuccess(response);
    return UserProfileDto.fromJson(response.data['data']);
  }

  static Future<UserProfileDto> acceptFriendRequest(String requestId) async {
    final response = await ApiClient.dio.post('/api/friend-requests/$requestId/accept');
    checkSuccess(response);
    return UserProfileDto.fromJson(response.data['data']);
  }

  static Future<UserProfileDto> declineFriendRequest(String requestId) async {
    final response = await ApiClient.dio.post('/api/friend-requests/$requestId/decline');
    checkSuccess(response);
    return UserProfileDto.fromJson(response.data['data']);
  }

  static Future<void> unfriend(String userId) async {
    final response = await ApiClient.dio.delete('/api/friends/$userId');
    checkSuccess(response);
  }

  static Future<void> block(String userId) async {
    final response = await ApiClient.dio.post('/api/blocks', data: {'userId': userId});
    checkSuccess(response);
  }

  static Future<void> unblock(String userId) async {
    final response = await ApiClient.dio.delete('/api/blocks/$userId');
    checkSuccess(response);
  }

  static Future<UserProfileDto> uploadProfilePhoto(XFile file) async {
    final lowerName = file.name.toLowerCase();
    final mediaType = lowerName.endsWith('.png')
        ? DioMediaType('image', 'png')
        : DioMediaType('image', 'jpeg');
    final response = await ApiClient.dio.post(
      '/api/account/profile-photo',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
          contentType: mediaType,
        ),
      }),
    );
    checkSuccess(response);
    return UserProfileDto.fromJson(response.data['data']);
  }

  static Future<void> removeProfilePhoto() async {
    final response = await ApiClient.dio.delete('/api/account/profile-photo');
    checkSuccess(response);
  }
}
