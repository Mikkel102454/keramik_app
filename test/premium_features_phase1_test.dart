import 'package:ceramic_app/objects/ceramic_batch_delete_dto.dart';
import 'package:ceramic_app/objects/ceramic_batch_edit_dto.dart';
import 'package:ceramic_app/objects/project_template_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/ui/pages/home/batch/ceramic_batch_delete_review_dialog.dart';
import 'package:ceramic_app/ui/pages/home/batch/ceramic_batch_edit_page.dart';
import 'package:ceramic_app/ui/pages/home/templates/project_template_editor_page.dart';
import 'package:ceramic_app/ui/pages/home/templates/project_templates_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  test(
    'template DTO preserves planning data and unavailable material state',
    () {
      final value = ProjectTemplateDto.fromJson({
        'id': 7,
        'version': 2,
        'name': 'Cup plan',
        'titlePattern': 'Cup {n}',
        'clayId': null,
        'clayTitle': 'Deleted clay',
        'clayAvailable': false,
        'note': 'Pull handle',
        'heightCm': 10,
        'widthCm': null,
        'depthCm': null,
        'diameterCm': 8,
        'tags': ['series'],
        'glazes': [
          {
            'glazeId': 4,
            'glazeTitle': 'White',
            'available': true,
            'note': 'Rim',
            'layerOrder': 1,
            'coatCount': 2,
          },
        ],
        'firings': [
          {
            'type': 'BISQUE',
            'firingDate': null,
            'targetCone': '04',
            'targetTemperatureC': 1060,
            'kiln': '',
            'program': '',
            'note': '',
            'firingOrder': 1,
          },
        ],
        'createdAt': '2026-07-26T00:00:00Z',
        'updatedAt': '2026-07-26T00:00:00Z',
      });

      expect(value.clayAvailable, isFalse);
      expect(value.glazes.single.coatCount, 2);
      expect(value.firings.single.type, 'BISQUE');
      expect(value.toRequestJson(), isNot(contains('rating')));
      expect(value.toRequestJson(), isNot(contains('outcomeNote')));
    },
  );

  test('batch result distinguishes stale or protected skips from updates', () {
    final value = CeramicBatchResultDto.fromJson({
      'selectedCount': 2,
      'updatedCount': 1,
      'skippedCount': 1,
      'targets': [
        {
          'ceramicId': 1,
          'title': 'A',
          'updated': true,
          'status': 'UPDATED_WITH_SKIPS',
          'warnings': ['Glaze plan skipped'],
        },
        {
          'ceramicId': 2,
          'title': 'B',
          'updated': false,
          'status': 'SKIPPED_STALE',
          'warnings': ['Ceramic changed after the preview'],
        },
      ],
    });

    expect(value.updatedCount, 1);
    expect(value.targets.last.status, 'SKIPPED_STALE');
    expect(value.targets.first.warnings, isNotEmpty);
  });

  test('batch deletion preview preserves review tokens and titles', () {
    final value = CeramicBatchDeletePreviewDto.fromJson({
      'selectedCount': 2,
      'targets': [
        {
          'ceramicId': 4,
          'title': 'Cup 1',
          'expectedUpdatedAt': '2026-07-26T12:00:00Z',
        },
        {
          'ceramicId': 5,
          'title': 'Cup 2',
          'expectedUpdatedAt': '2026-07-26T12:01:00Z',
        },
      ],
    });

    expect(value.selectedCount, 2);
    expect(value.targets.last.title, 'Cup 2');
    expect(value.targets.first.toApplyJson(), {
      'ceramicId': 4,
      'expectedUpdatedAt': '2026-07-26T12:00:00.000Z',
    });
  });

  test(
    'template controller exposes retryable load errors and recovers',
    () async {
      var fail = true;
      final controller = ProjectTemplatesController(
        loader: ({cursor}) async {
          if (fail) throw StateError('offline');
          return const ProjectTemplatePageDto(items: []);
        },
        clayLoader: () async => [],
        glazeLoader: () async => [],
      );

      await controller.load();
      expect(controller.error, isNotNull);
      fail = false;
      await controller.load();
      expect(controller.error, isNull);
      expect(controller.templates, isEmpty);
      controller.dispose();
    },
  );

  testWidgets('template editor remains usable on a compact layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      localizedTestApp(
        home: const ProjectTemplateEditorPage(clays: [], glazes: []),
      ),
    );
    await tester.pump();

    expect(find.text('Create template'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('batch edit uses spaced sections on a compact layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      localizedTestApp(
        home: CeramicBatchEditPage(
          ceramicIds: const [1, 2],
          stages: [StageDto(id: 1, title: 'Ideas')],
          clays: const [],
          templateLoader: () async =>
              const ProjectTemplatePageDto(items: []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Basics'), findsOneWidget);
    expect(find.text('Tag changes'), findsOneWidget);
    expect(find.byType(Card), findsAtLeastNWidgets(3));
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Apply dimensions'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Height (cm)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('batch delete review is scrollable on a compact layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final preview = CeramicBatchDeletePreviewDto(
      selectedCount: 50,
      targets: List.generate(
        50,
        (index) => CeramicBatchDeleteTargetDto(
          ceramicId: index + 1,
          title: 'Piece ${index + 1}',
          expectedUpdatedAt: DateTime.utc(2026, 7, 26),
        ),
      ),
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: CeramicBatchDeleteReviewDialog(preview: preview),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review deletion'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -140));
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete 50'),
    );
    expect(deleteButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
