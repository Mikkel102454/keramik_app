import 'package:ceramic_app/objects/public_ceramic_card_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/ui/pages/profile/basic_profile_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  test('parses the public finished-ceramic card contract', () {
    final card = PublicCeramicCardDto.fromJson({
      'imageUrl': null,
      'title': 'Public vase',
      'stage': 'Finished',
      'clayTitle': 'Porcelain',
      'rating': 5,
    });

    expect(card.title, 'Public vase');
    expect(card.stage, 'Finished');
    expect(card.clayTitle, 'Porcelain');
    expect(card.rating, 5);
  });

  testWidgets('searched profile includes its read-only finished pieces', (
    tester,
  ) async {
    const profile = UserProfileDto(
      userId: 'member-id',
      username: 'potter',
      avatarInitials: 'PO',
      avatarColor: '#355070',
      relationshipState: 'NONE',
      actions: <String>{},
    );
    await tester.pumpWidget(
      localizedTestApp(
        home: BasicProfilePage(
          initialProfile: profile,
          loadFinishedCeramics: (_) async => const [
            PublicCeramicCardDto(
              title: 'Public vase',
              stage: 'Finished',
              clayTitle: 'Porcelain',
              rating: 5,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('potter'), findsOneWidget);
    expect(find.text('Finished pieces'), findsOneWidget);
    expect(find.text('Public vase'), findsOneWidget);
    expect(find.text('Porcelain'), findsOneWidget);
  });
}
