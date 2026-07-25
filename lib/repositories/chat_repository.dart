import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/chat_report_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class ChatRepository {
  static Future<int> getBadgeCount() async {
    return (await getBadge()).count;
  }

  static Future<ChatBadgeDto> getBadge() async {
    final response = await ApiClient.dio.get('/api/chat/badge');
    checkSuccess(response);
    return ChatBadgeDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  static Future<CursorPage<DirectConversationDto>> getConversations({
    String? cursor,
    bool archived = false,
  }) async {
    final query = <String, dynamic>{'limit': 20, 'archived': archived};
    if (cursor case final value?) query['cursor'] = value;
    final response = await ApiClient.dio.get(
      '/api/chat/conversations',
      queryParameters: query,
    );
    checkSuccess(response);
    return CursorPage.fromJson(
      response.data['data'],
      DirectConversationDto.fromJson,
    );
  }

  static Future<DirectConversationDto> getConversation(String id) async {
    final response = await ApiClient.dio.get('/api/chat/conversations/$id');
    checkSuccess(response);
    return DirectConversationDto.fromJson(response.data['data']);
  }

  static Future<DirectConversationDto> createDirect(String userId) async {
    final response = await ApiClient.dio.post(
      '/api/chat/direct',
      data: {'userId': userId},
    );
    checkSuccess(response);
    return DirectConversationDto.fromJson(response.data['data']);
  }

  static Future<DirectConversationDto> createRequest(
    String userId,
    String clientMessageId,
    String message,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/chat/direct/requests',
      data: {
        'userId': userId,
        'clientMessageId': clientMessageId,
        'message': message,
      },
    );
    checkSuccess(response);
    return DirectConversationDto.fromJson(response.data['data']);
  }

  static Future<DirectConversationDto> createGroup(
    String name,
    List<String> memberIds,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/chat/groups',
      data: {'name': name, 'memberIds': memberIds},
    );
    checkSuccess(response);
    return DirectConversationDto.fromJson(response.data['data']);
  }

  static Future<DirectConversationDto> renameGroup(
    String id,
    String name,
  ) async {
    final response = await ApiClient.dio.put(
      '/api/chat/groups/$id/name',
      data: {'name': name},
    );
    checkSuccess(response);
    return DirectConversationDto.fromJson(response.data['data']);
  }

  static Future<DirectConversationDto> addGroupMembers(
    String id,
    List<String> userIds,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/chat/groups/$id/members',
      data: {'userIds': userIds},
    );
    checkSuccess(response);
    return DirectConversationDto.fromJson(response.data['data']);
  }

  static Future<void> leaveGroup(String id) async {
    final response = await ApiClient.dio.delete(
      '/api/chat/groups/$id/membership',
    );
    checkSuccess(response);
  }

  static Future<DirectConversationDto> accept(String id) =>
      _changeRequest(id, 'accept');
  static Future<DirectConversationDto> decline(String id) =>
      _changeRequest(id, 'decline');

  static Future<DirectConversationDto> _changeRequest(
    String id,
    String action,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/chat/conversations/$id/$action',
    );
    checkSuccess(response);
    return DirectConversationDto.fromJson(response.data['data']);
  }

  static Future<ChatMessagePageDto> getMessages(
    String id, {
    String? before,
  }) async {
    final query = <String, dynamic>{'limit': 50};
    if (before case final value?) query['before'] = value;
    final response = await ApiClient.dio.get(
      '/api/chat/conversations/$id/messages',
      queryParameters: query,
    );
    checkSuccess(response);
    return ChatMessagePageDto.fromJson(response.data['data']);
  }

  static Future<ChatMessageDto> send(
    String id,
    String clientMessageId,
    String body,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/chat/conversations/$id/messages',
      data: {'clientMessageId': clientMessageId, 'body': body},
    );
    checkSuccess(response);
    return ChatMessageDto.fromJson(response.data['data']);
  }

  static Future<void> markRead(String id, String messageId) async {
    final response = await ApiClient.dio.put(
      '/api/chat/conversations/$id/read',
      data: {'messageId': messageId},
    );
    checkSuccess(response);
  }

  static Future<void> archive(String id) async {
    final response = await ApiClient.dio.put(
      '/api/chat/conversations/$id/archive',
    );
    checkSuccess(response);
  }

  static Future<void> restore(String id) async {
    final response = await ApiClient.dio.delete(
      '/api/chat/conversations/$id/archive',
    );
    checkSuccess(response);
  }

  static Future<ChatReportReceiptDto> reportMessage({
    required String conversationId,
    required String messageId,
    required ChatReportCategory category,
    String? explanation,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/chat/reports',
      data: {
        'conversationId': conversationId,
        'messageId': messageId,
        'category': category.apiValue,
        'explanation': explanation,
      },
    );
    checkSuccess(response);
    return ChatReportReceiptDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
