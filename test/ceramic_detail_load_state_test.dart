import 'dart:async';

import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_view/ceramic_view_page.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_view/ceramic_view_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets(
    'initial failure disables mutations and retry retains route seed',
    (tester) async {
      final seed = CeramicDto(
        id: 41,
        stageId: 1,
        title: 'Journal piece',
        clayTypeId: 0,
        rating: 0,
        weight: 0,
        note: '',
        glazes: [],
        tags: [],
        images: [],
      );
      final stages = [StageDto(id: 1, title: 'Idea')];
      final controller = _FailingLoadController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        localizedTestApp(
          home: CeramicViewPage(
            ceramic: seed,
            stages: stages,
            clayTypes: const [],
            glazes: const [],
            controller: controller,
          ),
        ),
      );

      final saveTemplate = find.widgetWithIcon(
        IconButton,
        Icons.content_copy_outlined,
      );
      final delete = find.widgetWithIcon(IconButton, Icons.delete);
      expect(tester.widget<IconButton>(saveTemplate).onPressed, isNull);
      expect(tester.widget<IconButton>(delete).onPressed, isNull);
      expect(controller.loads.single.$1, same(seed));
      expect(controller.loads.single.$2, same(stages));

      controller.failLoad();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(saveTemplate).onPressed, isNull);
      expect(tester.widget<IconButton>(delete).onPressed, isNull);
      expect(find.text('private transport detail'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(controller.loads, hasLength(2));
      expect(controller.loads.last.$1, same(seed));
      expect(controller.loads.last.$2, same(stages));
      expect(tester.widget<IconButton>(delete).onPressed, isNull);
      expect(tester.takeException(), isNull);

      controller.failLoad();
      await tester.pumpAndSettle();
      controller.recover(seed, stages);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(saveTemplate).onPressed, isNotNull);
      expect(tester.widget<IconButton>(delete).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _FailingLoadController extends CeramicViewPageController {
  final loads = <(CeramicDto?, List<StageDto>?)>[];
  late Completer<void> _pending;
  bool _loading = true;
  String? _failure;

  @override
  bool get isLoading => _loading;
  @override
  String? get error => _failure;

  @override
  Future<void> load(CeramicDto? seed, List<StageDto>? routeStages) async {
    loads.add((seed, routeStages));
    _loading = true;
    _failure = null;
    _pending = Completer<void>();
    notifyListeners();
    await _pending.future;
    _loading = false;
    _failure = 'private transport detail';
    notifyListeners();
  }

  void failLoad() => _pending.complete();

  void recover(CeramicDto seed, List<StageDto> routeStages) {
    ceramic = seed;
    stages = routeStages;
    viewRecorded = true;
    _loading = false;
    _failure = null;
    notifyListeners();
  }
}
