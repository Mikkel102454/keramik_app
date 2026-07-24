import 'package:ceramic_app/objects/ceramic_firing_dto.dart';
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/ui/widgets/firing_editor_dialog.dart';
import 'package:ceramic_app/ui/widgets/glaze_application_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('glaze editor disposes safely after cancel', (tester) async {
    await tester.pumpWidget(_glazeEditor());

    await tester.tap(find.text('Satin white'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('glaze editor saves before closing and disposes safely', (
    tester,
  ) async {
    String? savedNote;
    int? savedCoats;
    await tester.pumpWidget(
      _glazeEditor(
        onEdit: (_, note, coats) async {
          savedNote = note;
          savedCoats = coats;
          return true;
        },
      ),
    );

    await tester.tap(find.text('Satin white'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '3');
    await tester.enterText(find.byType(TextField).at(1), 'Rim and handle');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(savedNote, 'Rim and handle');
    expect(savedCoats, 3);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('glaze editor remains scrollable above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_glazeEditor());

    await tester.tap(find.text('Satin white'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('firing editor disposes safely after cancel', (tester) async {
    await tester.pumpWidget(
      _dialogLauncher(
        (context) =>
            FiringEditorDialog(ceramicId: 12, onSave: (_) async => true),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('firing editor saves before closing and disposes safely', (
    tester,
  ) async {
    CeramicFiringDto? saved;
    await tester.pumpWidget(
      _dialogLauncher(
        (context) => FiringEditorDialog(
          ceramicId: 12,
          onSave: (firing) async {
            saved = firing;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved?.ceramicId, 12);
    expect(saved?.status, 'PLANNED');
    expect(saved?.type, 'BISQUE');
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _glazeEditor({
  Future<bool> Function(int entryId, String note, int coatCount)? onEdit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: GlazeApplicationEditor(
        entries: [
          CeramicGlazeEntryDto(
            id: 7,
            glazeId: 4,
            ceramicId: 12,
            note: 'Foot',
            coatCount: 2,
          ),
        ],
        glazes: [GlazeDto(id: 4, title: 'Satin white')],
        onAdd: (_) async => true,
        onEdit: onEdit ?? (_, _, _) async => true,
        onDelete: (_) async => true,
        onMove: (_, _) async => true,
      ),
    ),
  );
}

Widget _dialogLauncher(WidgetBuilder dialogBuilder) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () =>
              showDialog<void>(context: context, builder: dialogBuilder),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}
