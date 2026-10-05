import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/objects/user_profile_dto.dart';
import 'package:clay_dock/ui/pages/notification/ceramic_sharing_pages.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('publication sharing lists only writable conversations', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      localizedTestApp(
        home: ShareCeramicConversationPickerPage.publication(
          publicationId: 'publication-id',
          loadConversations: ({cursor}) async => CursorPage(
            items: [
              _conversation('active', 'Studio friends'),
              _conversation('readonly', 'Former group', readOnly: true),
              _conversation('archived', 'Archived chat', archived: true),
            ],
          ),
          confirmShare: (_) async => true,
          sendPublication:
              (conversationId, clientMessageId, publicationId) async {
                sent.add('$conversationId|$publicationId|$clientMessageId');
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Studio friends'), findsOneWidget);
    expect(find.text('Former group'), findsNothing);
    expect(find.text('Archived chat'), findsNothing);

    await tester.tap(find.text('Studio friends'));
    await tester.pumpAndSettle();
    expect(sent, hasLength(1));
    expect(sent.single, startsWith('active|publication-id|'));
  });

  testWidgets('publication sharing explains when no conversation is writable', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: ShareCeramicConversationPickerPage.publication(
          publicationId: 'publication-id',
          loadConversations: ({cursor}) async => CursorPage(
            items: [_conversation('readonly', 'Former group', readOnly: true)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No writable conversations are available.'),
      findsOneWidget,
    );
  });
}

DirectConversationDto _conversation(
  String id,
  String title, {
  bool readOnly = false,
  bool archived = false,
}) => DirectConversationDto(
  id: id,
  status: 'ACTIVE',
  type: 'DIRECT',
  title: title,
  avatarInitials: 'SF',
  avatarColor: '#355070',
  unreadCount: 0,
  archived: archived,
  incomingRequest: false,
  readOnly: readOnly,
);
