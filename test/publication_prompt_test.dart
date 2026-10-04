import 'package:ceramic_app/ui/pages/discover/publication_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets(
    'finished ceramic without an image stays saved but cannot publish',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        _promptLauncher(hasImage: false, onResult: (value) => result = value),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add a photo to publish'), findsOneWidget);
      expect(find.textContaining('Your piece is saved.'), findsOneWidget);
      expect(find.textContaining('Published, but hidden'), findsNothing);
      expect(find.text('Publish'), findsNothing);
      expect(find.text('Not now'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    },
  );

  testWidgets('publishing remains an explicit choice for a finished ceramic', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _promptLauncher(hasImage: true, onResult: (value) => result = value),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Publish'), findsOneWidget);

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}

Widget _promptLauncher({
  required bool hasImage,
  required ValueChanged<bool> onResult,
}) => localizedTestApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => FilledButton(
        onPressed: () async {
          onResult(
            await showFinishedPublicationPrompt(context, hasImage: hasImage),
          );
        },
        child: const Text('Open'),
      ),
    ),
  ),
);
