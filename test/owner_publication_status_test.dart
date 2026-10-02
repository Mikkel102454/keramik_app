import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/ui/pages/discover/owner_publication_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('published owner state shows audience and unpublish action', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: OwnerPublicationStatusCard(
            status: _status(currentAudience: 'EVERYONE'),
            onToggle: () async {
              toggles++;
              return true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Discover'), findsOneWidget);
    expect(
      find.textContaining('Visible to all active members'),
      findsOneWidget,
    );
    await tester.tap(find.text('Unpublish'));
    await tester.pump();
    expect(toggles, 1);
  });

  testWidgets('unpublished owner state offers the publish action', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: OwnerPublicationStatusCard(
            status: _status(current: false, state: 'UNPUBLISHED'),
            onToggle: () async {
              toggles++;
              return true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Unpublish'), findsNothing);
    await tester.tap(find.text('Publish'));
    await tester.pump();
    expect(toggles, 1);
  });

  testWidgets('temporary and moderation states explain restrictions', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: Column(
            children: [
              OwnerPublicationStatusCard(
                status: _status(eligible: false, currentAudience: 'FRIENDS'),
                onToggle: () async => true,
              ),
              OwnerPublicationStatusCard(
                status: _status(state: 'MODERATION_REMOVED'),
                onToggle: () async => true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Published, but hidden'), findsOneWidget);
    expect(find.textContaining('Friends only'), findsOneWidget);
    expect(find.textContaining('Removed by moderation'), findsOneWidget);
    final moderationButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Unpublish').last,
    );
    expect(moderationButton.onPressed, isNull);
  });
}

PublicationStatusDto _status({
  String state = 'PUBLISHED',
  bool current = true,
  bool eligible = true,
  String currentAudience = 'EVERYONE',
}) => PublicationStatusDto(
  publicationId: 'publication-id',
  state: state,
  current: current,
  eligible: eligible,
  currentAudience: currentAudience,
  replayed: false,
  changed: false,
);
