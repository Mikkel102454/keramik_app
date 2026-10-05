import 'package:clay_dock/ui/pages/discover/publication_report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('publication report validates Other and returns trimmed draft', (
    tester,
  ) async {
    PublicationReportDraft? draft;
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                draft = await showPublicationReportDialog(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('securely preserved'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    for (final category in [
      'Spam',
      'Harassment or hate',
      'Sexual content',
      'Violence or dangerous content',
      'Stolen work or intellectual property',
      'Other',
    ]) {
      expect(find.text(category), findsWidgets);
    }
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'short');
    await tester.tap(find.text('Submit report'));
    await tester.pump();
    expect(
      find.text('Add an explanation when choosing Other.'),
      findsOneWidget,
    );
    expect(draft, isNull);

    await tester.enterText(
      find.byType(TextFormField),
      '  This gives enough context.  ',
    );
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(draft?.category, 'OTHER');
    expect(draft?.explanation, 'This gives enough context.');
  });

  testWidgets('stolen-work report requires an explanation', (tester) async {
    PublicationReportDraft? draft;
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                draft = await showPublicationReportDialog(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Stolen work or intellectual property').last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit report'));
    await tester.pump();
    expect(
      find.text('Add an explanation when choosing Other.'),
      findsOneWidget,
    );
    expect(draft, isNull);

    await tester.enterText(
      find.byType(TextFormField),
      '  This design copies my original work.  ',
    );
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(draft?.category, 'STOLEN_WORK_OR_IP');
    expect(draft?.explanation, 'This design copies my original work.');
  });
}
