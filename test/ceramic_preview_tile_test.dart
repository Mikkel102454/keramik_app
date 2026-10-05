import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clay_dock/l10n/app_localizations.dart';
import 'package:clay_dock/ui/theme/studio_theme.dart';
import 'package:clay_dock/ui/widgets/ceramic_journal_card.dart';
import 'package:clay_dock/ui/widgets/ceramic_preview_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const title = 'A long handmade ceramic bowl';
  const captureKey = Key('preview');
  for (final dark in [false, true]) {
    final theme = dark ? StudioTheme.dark() : StudioTheme.light();
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Home and Profile previews paint identically: dark=$dark, text=$scale',
        (tester) async {
          Widget app(Widget tile) => MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: captureKey,
                  child: SizedBox(width: 126, height: 175, child: tile),
                ),
              ),
            ),
          );
          Future<Uint8List> pixels(Widget tile) async {
            await tester.pumpWidget(app(tile));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            _expectCenteredPlaceholder(tester, title);
            return (await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(captureKey),
              );
              final image = await boundary.toImage(pixelRatio: 1);
              try {
                return (await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                ))!.buffer.asUint8List();
              } finally {
                image.dispose();
              }
            }))!;
          }

          final home = await pixels(
            CeramicJournalCard.public(
              publicTitle: title,
              publicRating: 4,
              publicImageUrl: null,
              stageTitle: 'Finished',
              clayTitle: 'Stoneware',
              onTap: () {},
            ),
          );
          final profile = await pixels(
            CeramicPreviewTile(
              title: title,
              subtitle: 'Stoneware',
              stageTitle: 'Finished',
              rating: 4,
              onTap: () {},
            ),
          );
          expect(home, orderedEquals(profile));
        },
      );
    }

    testWidgets(
      'title-only placeholder stays centered above its caption: dark=$dark',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 190,
                  height: 285,
                  child: CeramicPreviewTile(title: title, onTap: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        _expectCenteredPlaceholder(tester, title);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'public preview keeps failed-photo fallback, likes and detail action: dark=$dark',
      (tester) async {
        var opens = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 105,
                    height: 146,
                    child: CeramicPreviewTile(
                      title: title,
                      subtitle: 'Speckled stoneware',
                      stageTitle: 'Finished',
                      rating: 4,
                      likeCount: 12345,
                      imageUrl: 'https://example.invalid/ceramic.jpg',
                      onTap: () => opens++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
        expect(find.text('12345'), findsOneWidget);
        expect(find.text('Finished'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('Speckled stoneware'), findsOneWidget);
        _expectCenteredPlaceholder(tester, title);
        await tester.tap(find.byType(CeramicPreviewTile));
        await tester.pump();
        expect(opens, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

void _expectCenteredPlaceholder(WidgetTester tester, String title) {
  final tile = tester.getRect(find.byType(CeramicPreviewTile));
  final caption = tester.getRect(
    find.ancestor(of: find.text(title), matching: find.byType(Container)).first,
  );
  final icon = tester.getRect(find.byIcon(Icons.handyman_outlined));
  expect(icon.center.dx, closeTo(tile.center.dx, .01));
  expect(icon.center.dy, closeTo((tile.top + caption.top) / 2, .01));
  expect(icon.bottom, lessThan(caption.top));
}
