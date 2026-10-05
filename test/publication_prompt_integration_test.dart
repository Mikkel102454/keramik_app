import 'dart:async';

import 'package:clay_dock/objects/ceramic_dto.dart';
import 'package:clay_dock/objects/clay_dto.dart';
import 'package:clay_dock/objects/image_dto.dart';
import 'package:clay_dock/objects/stage_dto.dart';
import 'package:clay_dock/ui/pages/home/ceramic_create/ceramic_create_page.dart';
import 'package:clay_dock/ui/pages/home/ceramic_create/ceramic_create_page_controller.dart';
import 'package:clay_dock/ui/pages/home/ceramic_view/ceramic_view_page.dart';
import 'package:clay_dock/ui/pages/home/ceramic_view/ceramic_view_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets(
    'saving blocks duplicate submission and back until creation completes',
    (tester) async {
      final controller = _PendingCreateController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        localizedTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CeramicCreatePage(
                      stages: _stages,
                      clayTypes: [_clay],
                      glazes: const [],
                      controller: controller,
                    ),
                  ),
                ),
                child: const Text('Create test piece'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Create test piece'));
      await tester.pumpAndSettle();
      final save = find.byTooltip('Save');
      await tester.tap(save);
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(of: save, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(CeramicCreatePage), findsOneWidget);
      expect(controller.calls, 1);
      controller.result.complete(_ceramic(stageId: 1));
      await tester.pumpAndSettle();
      expect(find.byType(CeramicCreatePage), findsNothing);
      expect(controller.calls, 1);
    },
  );

  testWidgets(
    'failed optional publication keeps the saved piece and returns to journal',
    (tester) async {
      final controller = _CreateController();
      addTearDown(controller.dispose);
      bool? saved;
      await tester.pumpWidget(
        localizedTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => CeramicCreatePage(
                        stages: _stages,
                        clayTypes: [_clay],
                        glazes: const [],
                        controller: controller,
                        publishCeramic: (_) async =>
                            throw Exception('private transport detail'),
                      ),
                    ),
                  );
                },
                child: const Text('Create test piece'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Create test piece'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      expect(find.byType(CeramicCreatePage), findsNothing);
      expect(
        find.text(
          'Your piece was saved. Publishing could not be confirmed. Open the piece to check or try again.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('private transport'), findsNothing);
    },
  );

  testWidgets('creating a Finished ceramic asks before publishing', (
    tester,
  ) async {
    final controller = _CreateController();
    addTearDown(controller.dispose);
    int? publishedCeramicId;
    await tester.pumpWidget(
      localizedTestApp(
        home: CeramicCreatePage(
          stages: _stages,
          clayTypes: [_clay],
          glazes: const [],
          controller: controller,
          publishCeramic: (ceramicId) async {
            publishedCeramicId = ceramicId;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('Publish this finished piece?'), findsOneWidget);
    expect(publishedCeramicId, isNull);

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(publishedCeramicId, 42);
  });

  testWidgets(
    'transition into Finished saves without a publication popup or auto-publish',
    (tester) async {
      final controller = _ViewController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        localizedTestApp(
          home: CeramicViewPage(
            ceramic: controller.ceramic,
            stages: _stages,
            clayTypes: [_clay],
            glazes: const [],
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Finished'));
      await tester.tap(find.text('Finished'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Add a photo to publish'), findsNothing);
      expect(find.text('Publish this finished piece?'), findsNothing);
      expect(controller.toggleCount, 0);
      expect(controller.ceramic.stageId, 2);
    },
  );

  testWidgets('creating a non-Finished ceramic never offers publication', (
    tester,
  ) async {
    final controller = _NonFinishedCreateController();
    addTearDown(controller.dispose);
    var publishCalls = 0;
    await tester.pumpWidget(
      localizedTestApp(
        home: CeramicCreatePage(
          stages: _stages,
          clayTypes: [_clay],
          glazes: const [],
          controller: controller,
          publishCeramic: (_) async {
            publishCalls++;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('Publish this finished piece?'), findsNothing);
    expect(publishCalls, 0);
  });
}

final _stages = [
  StageDto(id: 1, title: 'Ideas'),
  StageDto(id: 2, title: 'Finished'),
];

final _clay = ClayDto(
  title: 'Stoneware',
  note: '',
  id: 1,
  supplier: '',
  images: [],
);

CeramicDto _ceramic({required int stageId, List<ImageDto>? images}) =>
    CeramicDto(
      id: 42,
      stageId: stageId,
      title: 'Finished bowl',
      clayTypeId: 1,
      rating: 4,
      weight: 1,
      note: '',
      glazes: [],
      tags: [],
      images: images ?? [],
    );

class _CreateController extends CeramicCreatePageController {
  _CreateController() {
    title = 'Finished bowl';
    clayTypeId = 1;
    stageId = 2;
    rating = 4;
  }

  @override
  Future<void> load() async {}

  @override
  Future<CeramicDto> create() async => _ceramic(
    stageId: 2,
    images: [
      ImageDto(id: 7, uri: 'https://example.invalid/image', objectId: 42),
    ],
  );
}

class _ViewController extends CeramicViewPageController {
  _ViewController() {
    ceramic = _ceramic(stageId: 1);
    stages = _stages;
  }

  int toggleCount = 0;

  @override
  Future<void> load(CeramicDto? ceramicDto, List<StageDto>? values) async {}

  @override
  Future<bool> setStage(int value) async {
    ceramic.stageId = value;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> togglePublication() async {
    toggleCount++;
    return true;
  }
}

class _NonFinishedCreateController extends CeramicCreatePageController {
  _NonFinishedCreateController() {
    title = 'Work in progress';
    clayTypeId = 1;
    stageId = 1;
    rating = 4;
  }

  @override
  Future<void> load() async {}

  @override
  Future<CeramicDto> create() async => _ceramic(stageId: 1);
}

class _PendingCreateController extends _NonFinishedCreateController {
  final result = Completer<CeramicDto>();
  int calls = 0;

  @override
  Future<CeramicDto> create() {
    calls++;
    return result.future;
  }
}
