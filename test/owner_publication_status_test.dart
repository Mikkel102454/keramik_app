import 'package:clay_dock/objects/publication_dto.dart';
import 'package:clay_dock/ui/pages/discover/owner_publication_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets(
    'Everyone audience omits explanation and keeps unpublish action',
    (tester) async {
      var toggles = 0;
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: OwnerPublicationStatusCard(
              status: _status(currentAudience: 'EVERYONE'),
              isFinished: true,
              hasImage: true,
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
        findsNothing,
      );
      await tester.tap(find.text('Unpublish'));
      await tester.pump();
      expect(toggles, 1);
    },
  );

  testWidgets('unpublished owner state offers the publish action', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: OwnerPublicationStatusCard(
            status: _status(current: false, state: 'UNPUBLISHED'),
            isFinished: true,
            hasImage: true,
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
                isFinished: false,
                hasImage: false,
                onToggle: () async => true,
              ),
              OwnerPublicationStatusCard(
                status: _status(state: 'MODERATION_REMOVED'),
                isFinished: true,
                hasImage: true,
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

  for (final locale in [const Locale('en'), const Locale('da')]) {
    testWidgets(
      'publication requirements update live in ${locale.languageCode}',
      (tester) async {
        var toggles = 0;
        final danish = locale.languageCode == 'da';
        final publish = danish ? 'Udgiv' : 'Publish';
        final stage = danish
            ? 'Sæt stadiet til Færdigt'
            : 'Set the stage to Finished';
        final photo = danish
            ? 'Tilføj mindst ét billede'
            : 'Add at least one photo';

        Future<void> show({
          required bool finished,
          required bool hasImage,
        }) async {
          await tester.pumpWidget(
            localizedTestApp(
              locale: locale,
              home: Scaffold(
                body: OwnerPublicationStatusCard(
                  // The API's no-publication status has eligible=false even for
                  // a ready piece; current journal data drives the requirements.
                  status: _status(current: false, eligible: false),
                  isFinished: finished,
                  hasImage: hasImage,
                  onToggle: () async {
                    toggles++;
                    return true;
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        for (final requirements in [
          (false, false),
          (true, false),
          (false, true),
        ]) {
          await show(finished: requirements.$1, hasImage: requirements.$2);
          expect(find.text(stage), findsOneWidget);
          expect(find.text(photo), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, publish),
                )
                .onPressed,
            isNull,
          );
          expect(
            find.byIcon(Icons.check_circle_outline),
            findsNWidgets(requirements.$1 || requirements.$2 ? 1 : 0),
          );
          expect(toggles, 0);
        }

        await show(finished: true, hasImage: true);
        expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(2));
        await tester.tap(find.text(publish));
        await tester.pumpAndSettle();
        expect(toggles, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('hidden current publication can still be unpublished', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: OwnerPublicationStatusCard(
            status: _status(eligible: false),
            isFinished: false,
            hasImage: false,
            onToggle: () async {
              toggles++;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Unpublish'));
    await tester.pumpAndSettle();
    expect(toggles, 1);
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
