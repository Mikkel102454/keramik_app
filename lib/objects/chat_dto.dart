import 'package:ceramic_app/objects/user_profile_dto.dart';

class DirectConversationDto {
  const DirectConversationDto({
    required this.id,
    required this.status,
    required this.type,
    required this.title,
    required this.avatarInitials,
    required this.avatarColor,
    required this.unreadCount,
    required this.archived,
    required this.incomingRequest,
    required this.readOnly,
    this.otherUser,
    this.memberCount = 2,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.readOnlyReason,
  });

  final String id;
  final String status;
  final String type;
  final String title;
  final String avatarInitials;
  final String avatarColor;
  final int memberCount;
  final UserProfileDto? otherUser;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool archived;
  final bool incomingRequest;
  final bool readOnly;
  final String? readOnlyReason;

  factory DirectConversationDto.fromJson(Map<String, dynamic> json) {
    final otherUser = json['otherUser'] == null
        ? null
        : UserProfileDto.fromJson(json['otherUser'] as Map<String, dynamic>);
    return DirectConversationDto(
      id: json['id'] as String,
      status: json['status'] as String,
      type: json['type'] as String? ?? 'DIRECT',
      title: json['title'] as String? ?? otherUser?.username ?? 'Conversation',
      avatarInitials: json['avatarInitials'] as String? ?? otherUser?.avatarInitials ?? '?',
      avatarColor: json['avatarColor'] as String? ?? otherUser?.avatarColor ?? '#6D597A',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 2,
      otherUser: otherUser,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String).toLocal(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      archived: json['archived'] as bool? ?? false,
      incomingRequest: json['incomingRequest'] as bool? ?? false,
      readOnly: json['readOnly'] as bool? ?? false,
      readOnlyReason: json['readOnlyReason'] as String?,
    );
  }
}

class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.senderUserId,
    required this.body,
    required this.createdAt,
    required this.sequence,
    required this.mine,
    this.type = 'TEXT',
    this.senderUsername,
    this.senderAvatarUrl,
    this.senderAvatarInitials,
    this.senderAvatarColor,
  });

  final String id;
  final String senderUserId;
  final String body;
  final DateTime createdAt;
  final int sequence;
  final bool mine;
  final String type;
  final String? senderUsername;
  final String? senderAvatarUrl;
  final String? senderAvatarInitials;
  final String? senderAvatarColor;

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: json['id'] as String,
      senderUserId: json['senderUserId'] as String? ?? '',
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      sequence: (json['sequence'] as num).toInt(),
      mine: json['mine'] as bool,
      type: json['type'] as String? ?? 'TEXT',
      senderUsername: json['senderUsername'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      senderAvatarInitials: json['senderAvatarInitials'] as String?,
      senderAvatarColor: json['senderAvatarColor'] as String?,
    );
  }
}

class ChatMessagePageDto {
  const ChatMessagePageDto({required this.items, this.nextCursor});

  final List<ChatMessageDto> items;
  final String? nextCursor;

  factory ChatMessagePageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessagePageDto(
      items: (json['items'] as List)
          .map((item) => ChatMessageDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
