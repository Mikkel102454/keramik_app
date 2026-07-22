import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile DTO preserves relationship actions and avatar fallback', () {
    final profile = UserProfileDto.fromJson({
      'userId': '3bd7df68-8f40-4a17-b6fe-8452519928ec',
      'username': 'alice',
      'avatarUrl': null,
      'avatarInitials': 'AL',
      'avatarColor': '#355070',
      'relationshipState': 'INCOMING_PENDING',
      'friendRequestId': '15cb0ef0-74ed-43fa-8674-e73bdb0fafac',
      'actions': ['ACCEPT_FRIEND_REQUEST', 'DECLINE_FRIEND_REQUEST', 'BLOCK'],
    });

    expect(profile.avatarUrl, isNull);
    expect(profile.avatarInitials, 'AL');
    expect(profile.relationshipState, 'INCOMING_PENDING');
    expect(profile.actions, contains('BLOCK'));
  });

  test('cursor page parses profiles and next cursor', () {
    final page = CursorPage.fromJson(
      {
        'items': [
          {
            'userId': '3bd7df68-8f40-4a17-b6fe-8452519928ec',
            'username': 'alice',
            'avatarInitials': 'AL',
            'avatarColor': '#355070',
            'relationshipState': 'NONE',
            'actions': ['SEND_FRIEND_REQUEST'],
          },
        ],
        'nextCursor': 'opaque',
      },
      UserProfileDto.fromJson,
    );

    expect(page.items.single.username, 'alice');
    expect(page.nextCursor, 'opaque');
  });

  test('self account parses private read-only names', () {
    final account = AccountProfileDto.fromJson({
      'userId': '3bd7df68-8f40-4a17-b6fe-8452519928ec',
      'username': 'alice',
      'avatarInitials': 'AL',
      'avatarColor': '#355070',
      'forename': 'Alice',
      'surname': 'Stone',
    });

    expect(account.forename, 'Alice');
    expect(account.surname, 'Stone');
  });
}
