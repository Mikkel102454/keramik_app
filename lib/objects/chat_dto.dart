import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/objects/publication_dto.dart';

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
    this.lastMessageType,
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
  final String? lastMessageType;
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
      lastMessageType: json['lastMessageType'] as String?,
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
    this.ceramic,
    this.publication,
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
  final ChatCeramicCardDto? ceramic;
  final ChatPublicationCardDto? publication;

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
      ceramic: json['ceramic'] == null
          ? null
          : ChatCeramicCardDto.fromJson(json['ceramic'] as Map<String, dynamic>),
      publication: json['publication'] == null
          ? null
          : ChatPublicationCardDto.fromJson(
              json['publication'] as Map<String, dynamic>,
            ),
    );
  }
}

class ChatPublicationCardDto {
  const ChatPublicationCardDto({required this.available, this.publication});

  final bool available;
  final PublicationCardDto? publication;

  factory ChatPublicationCardDto.fromJson(Map<String, dynamic> json) =>
      ChatPublicationCardDto(
        available: json['available'] as bool? ?? false,
        publication: json['publication'] == null
            ? null
            : PublicationCardDto.fromJson(
                json['publication'] as Map<String, dynamic>,
              ),
      );
}

class ChatCeramicCardDto {
  const ChatCeramicCardDto({
    required this.available,
    this.imageUrl,
    this.title,
    this.stage,
    this.clayTitle,
    this.rating,
  });

  final bool available;
  final String? imageUrl;
  final String? title;
  final String? stage;
  final String? clayTitle;
  final int? rating;

  factory ChatCeramicCardDto.fromJson(Map<String, dynamic> json) {
    return ChatCeramicCardDto(
      available: json['available'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      title: json['title'] as String?,
      stage: json['stage'] as String?,
      clayTitle: json['clayTitle'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
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
class ChatBadgeDto {
  const ChatBadgeDto({
    required this.count,
    required this.directMessages,
    required this.messageRequests,
    required this.friendRequests,
    required this.groupActivity,
  });

  final int count;
  final int directMessages;
  final int messageRequests;
  final int friendRequests;
  final int groupActivity;

  factory ChatBadgeDto.fromJson(Map<String, dynamic> json) => ChatBadgeDto(
    count: (json['count'] as num?)?.toInt() ?? 0,
    directMessages: (json['directMessages'] as num?)?.toInt() ?? 0,
    messageRequests: (json['messageRequests'] as num?)?.toInt() ?? 0,
    friendRequests: (json['friendRequests'] as num?)?.toInt() ?? 0,
    groupActivity: (json['groupActivity'] as num?)?.toInt() ?? 0,
  );
}
