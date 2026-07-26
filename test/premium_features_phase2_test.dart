import 'package:ceramic_app/objects/practice_analytics_dto.dart';
import 'package:ceramic_app/ui/pages/analytics/practice_analytics_controller.dart';
import 'package:ceramic_app/ui/pages/analytics/practice_analytics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  test(
    'analytics DTO preserves missing values instead of inventing zeroes',
    () {
      final value = PracticeAnalyticsDto.fromJson(_analyticsJson(empty: true));

      expect(value.creationToFinished.averageSeconds, isNull);
      expect(value.creationToFinished.sampleCount, 0);
      expect(value.firingTemperatures, isNull);
      expect(value.hasCeramicData, isFalse);
    },
  );

  test('analytics controller exposes retryable errors and recovers', () async {
    var fail = true;
    final controller = PracticeAnalyticsController(
      loader: ({from, to}) async {
        if (fail) throw StateError('offline');
        return PracticeAnalyticsDto.fromJson(_analyticsJson());
      },
    );

    await controller.load(selectedRange: AnalyticsRange.days90);
    expect(controller.error, isNotNull);
    fail = false;
    await controller.load();
    expect(controller.error, isNull);
    expect(controller.data?.dataQuality.ceramicCount, 2);
    controller.dispose();
  });

  testWidgets('analytics remains accessible on a compact layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = PracticeAnalyticsController(
      loader: ({from, to}) async =>
          PracticeAnalyticsDto.fromJson(_analyticsJson()),
    );

    await tester.pumpWidget(
      localizedTestApp(home: PracticeAnalyticsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Practice analytics'), findsOneWidget);
    expect(find.text('Created and completed'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Created'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Created: 2',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}

Map<String, dynamic> _analyticsJson({bool empty = false}) => {
  'calculationVersion': 'v1',
  'from': '2026-01-01T00:00:00Z',
  'to': '2026-07-26T00:00:00Z',
  'activity': empty
      ? []
      : [
          {'bucketStart': '2026-07-01T00:00:00Z', 'created': 2, 'completed': 1},
        ],
  'stageDistribution': empty
      ? []
      : [
          {'stageId': 1, 'stage': 'Ideas', 'count': 2},
        ],
  'creationToFinished': {
    'averageSeconds': empty ? null : 90000,
    'sampleCount': empty ? 0 : 1,
  },
  'stageDurations': [],
  'ratingDistribution': empty
      ? []
      : [
          {'rating': 5, 'count': 1},
        ],
  'unratedCount': empty ? 0 : 1,
  'mostUsedClays': [],
  'mostUsedGlazes': [],
  'successfulCombinations': [],
  'firingTemperatures': null,
  'dataQuality': {
    'ceramicCount': empty ? 0 : 2,
    'legacyBaselineCount': 0,
    'trustedCompletionCount': empty ? 0 : 1,
    'closedStageVisitCount': 0,
  },
};
