import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/ui/theme/studio_theme.dart';
import 'package:ceramic_app/ui/widgets/v2/tag_input_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/star_stepper_select_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child, {double scale = 1}) => MaterialApp(
  theme: StudioTheme.dark(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('long scaled tags wrap and rejected deletion restores the tag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const text =
        'A very long stoneware experiment tag with detailed descriptive words';
    var removed = 0;
    await tester.pumpWidget(
      app(
        TagInputWidget(
          initialValues: const [TagEntry(id: 7, value: text)],
          onRemove: (id) async {
            expect(id, 7);
            removed++;
            return false;
          },
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(text), findsOneWidget);
    final chip = tester.widget<InputChip>(find.byType(InputChip));
    expect(chip.deleteButtonTooltipMessage, 'Delete');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(removed, 1);
    expect(find.text(text), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rating choices wrap on small widths and restore rejected selection',
    (tester) async {
      tester.view.physicalSize = const Size(240, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          StarStepperSelectWidget(
            initialValue: 2,
            onChanged: (rating) async => false,
          ),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.star_border).last);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsNWidgets(2));
      final controls = find.byType(InkWell);
      for (final element in controls.evaluate()) {
        expect(
          tester
              .getSize(
                find.byElementPredicate((candidate) => candidate == element),
              )
              .width,
          greaterThanOrEqualTo(48),
        );
      }
    },
  );
}
