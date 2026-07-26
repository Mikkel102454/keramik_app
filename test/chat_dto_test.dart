import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/chat_event_dto.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses split notification badge categories', () {
    final badge = ChatBadgeDto.fromJson(const {
      'count': 4,
      'directMessages': 1,
      'messageRequests': 2,
      'friendRequests': 3,
      'groupActivity': 4,
    });

    expect(badge.count, 4);
    expect(badge.directMessages, 1);
    expect(badge.messageRequests, 2);
    expect(badge.friendRequests, 3);
    expect(badge.groupActivity, 4);
  });

  test('parses direct conversation and encrypted-message API projections', () {
    final conversation = DirectConversationDto.fromJson({
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'status': 'ACTIVE',
      'otherUser': {
        'userId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'username': 'potter',
        'avatarUrl': null,
        'avatarInitials': 'PO',
        'avatarColor': '#355070',
        'relationshipState': 'FRIENDS',
        'friendRequestId': null,
        'actions': ['MESSAGE'],
      },
      'lastMessagePreview': 'Hello',
      'lastMessageType': 'TEXT',
      'lastMessageAt': '2026-07-22T10:30:00Z',
      'unreadCount': 2,
      'archived': false,
      'incomingRequest': false,
      'readOnly': false,
      'readOnlyReason': null,
    });
    final message = ChatMessageDto.fromJson({
      'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      'senderUserId': conversation.otherUser!.userId,
      'body': 'Hello',
      'createdAt': '2026-07-22T10:30:00Z',
      'sequence': 4,
      'mine': false,
    });

    expect(conversation.otherUser!.username, 'potter');
    expect(conversation.unreadCount, 2);
    expect(conversation.lastMessageType, 'TEXT');
    expect(message.sequence, 4);
    expect(message.mine, isFalse);
  });

  test('parses available and unavailable ceramic message projections', () {
    final available = ChatMessageDto.fromJson({
      'id': '11111111-1111-4111-8111-111111111111',
      'senderUserId': '22222222-2222-4222-8222-222222222222',
      'body': '',
      'createdAt': '2026-07-25T10:30:00Z',
      'sequence': 9,
      'mine': false,
      'type': 'CERAMIC',
      'ceramic': {
        'available': true,
        'imageUrl': 'https://example.test/image',
        'title': 'Live bowl',
        'stage': 'Glazed',
        'clayTitle': 'Stoneware',
        'rating': 5,
      },
    });
    final unavailable = ChatMessageDto.fromJson({
      'id': '33333333-3333-4333-8333-333333333333',
      'senderUserId': '22222222-2222-4222-8222-222222222222',
      'body': '',
      'createdAt': '2026-07-25T10:31:00Z',
      'sequence': 10,
      'mine': false,
      'type': 'CERAMIC',
      'ceramic': {'available': false},
    });

    expect(available.type, 'CERAMIC');
    expect(available.ceramic!.available, isTrue);
    expect(available.ceramic!.title, 'Live bowl');
    expect(available.ceramic!.stage, 'Glazed');
    expect(unavailable.ceramic!.available, isFalse);
    expect(unavailable.ceramic!.title, isNull);
  });

  test('parses live publication cards and unavailable placeholders', () {
    final available = ChatMessageDto.fromJson({
      'id': '11111111-1111-4111-8111-111111111111',
      'senderUserId': '22222222-2222-4222-8222-222222222222',
      'body': '',
      'createdAt': '2026-07-25T10:30:00Z',
      'sequence': 11,
      'mine': false,
      'type': 'PUBLICATION',
      'publication': {
        'available': true,
        'publication': {
          'publicationId': '44444444-4444-4444-8444-444444444444',
          'creator': {
            'userId': '22222222-2222-4222-8222-222222222222',
            'username': 'potter',
            'avatarUrl': null,
            'avatarInitials': 'PO',
            'avatarColor': '#355070',
          },
          'primaryImage': null,
          'title': 'Published bowl',
          'clay': 'Stoneware',
          'likeCount': 3,
          'likedByMe': false,
          'ownedByMe': false,
          'publishedAt': '2026-07-25T10:00:00Z',
        },
      },
    });
    final unavailable = ChatMessageDto.fromJson({
      'id': '33333333-3333-4333-8333-333333333333',
      'senderUserId': '22222222-2222-4222-8222-222222222222',
      'body': '',
      'createdAt': '2026-07-25T10:31:00Z',
      'sequence': 12,
      'mine': false,
      'type': 'PUBLICATION',
      'publication': {'available': false, 'publication': null},
    });

    expect(available.publication!.available, isTrue);
    expect(available.publication!.publication!.title, 'Published bowl');
    expect(unavailable.publication!.available, isFalse);
    expect(unavailable.publication!.publication, isNull);
  });

  test('creates RFC 4122 version 4 client IDs', () {
    final first = createClientUuid();
    final second = createClientUuid();

    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(second, isNot(first));
  });

  test('parses and deduplicates live invalidation events', () {
    final event = ChatEventDto.fromJson({
      'eventId': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
      'type': 'CHAT_CHANGED',
      'conversationType': 'DIRECT',
      'conversationId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'occurredAt': '2026-07-22T10:30:00Z',
    });
    final deduplicator = ChatEventDeduplicator(capacity: 2);

    expect(event.conversationId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    expect(deduplicator.accept(event.eventId), isTrue);
    expect(deduplicator.accept(event.eventId), isFalse);
    expect(deduplicator.accept('event-2'), isTrue);
    expect(deduplicator.accept('event-3'), isTrue);
    expect(deduplicator.accept(event.eventId), isTrue);
  });

  test('parses group identity and sender-labelled system messages', () {
    final group = DirectConversationDto.fromJson({
      'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
      'status': 'ACTIVE',
      'type': 'GROUP',
      'title': 'Kiln crew',
      'avatarInitials': 'KI',
      'avatarColor': '#2A9D8F',
      'memberCount': 3,
      'otherUser': null,
      'unreadCount': 0,
      'archived': false,
      'incomingRequest': false,
      'readOnly': false,
    });
    final system = ChatMessageDto.fromJson({
      'id': 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      'senderUserId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'senderUsername': 'potter',
      'body': 'potter renamed the group',
      'createdAt': '2026-07-22T10:30:00Z',
      'sequence': 2,
      'mine': false,
      'type': 'SYSTEM',
    });

    expect(group.type, 'GROUP');
    expect(group.otherUser, isNull);
    expect(group.memberCount, 3);
    expect(system.type, 'SYSTEM');
    expect(system.senderUsername, 'potter');
  });
}
