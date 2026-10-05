import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/glaze_dto.dart';
import 'package:clay_dock/objects/glaze_notebook_dto.dart';
import 'package:clay_dock/objects/ceramic_glaze_entry_dto.dart';
import 'package:clay_dock/objects/ceramic_firing_dto.dart';
import 'package:clay_dock/repositories/glaze_notebook_repository.dart';
import 'package:clay_dock/ui/pages/home/ceramic_create/ceramic_create_page_controller.dart';
import 'package:clay_dock/app/combination_application_controller.dart';
import 'package:clay_dock/ui/pages/materials/glazes/notebook/combination_application_dialog.dart';
import 'package:clay_dock/ui/pages/materials/glazes/notebook/glaze_notebook_controller.dart';
import 'package:clay_dock/ui/pages/materials/glazes/notebook/glaze_notebook_editor_page.dart';
import 'package:clay_dock/ui/pages/materials/glazes/notebook/glaze_notebook_page.dart';
import 'package:clay_dock/ui/widgets/firing_editor_dialog.dart';
import 'package:clay_dock/ui/widgets/glaze_application_editor.dart';
import 'test_app.dart';

GlazeNotebookDto recipe() => GlazeNotebookDto(
  id: 4,
  version: 8,
  name: 'Blue twice',
  layers: [
    NotebookLayerDto(
      id: 10,
      glazeId: 1,
      glazeTitle: 'Blue',
      coatCount: 1,
      note: 'Rim',
    ),
    NotebookLayerDto(
      id: 11,
      glazeId: 1,
      glazeTitle: 'Blue',
      coatCount: 3,
      note: 'Base',
    ),
  ],
  firings: [
    NotebookFiringDto(
      id: 12,
      atmosphere: 'REDUCTION',
      firing: CeramicFiringDto(
        id: 12,
        ceramicId: 0,
        status: 'PLANNED',
        type: 'GLAZE',
        targetTemperatureC: 1200,
      ),
    ),
  ],
);

void main() {
  setUp(CombinationApplicationController.clearSession);
  for (final tiles in [false, true]) {
    testWidgets('loaded ${tiles ? "tile" : "recipe"} list enables creation', (
      tester,
    ) async {
      ApiClient.dio = Dio(
        BaseOptions(baseUrl: 'http://localhost', validateStatus: (_) => true),
      )..httpClientAdapter = NotebookListAdapter();
      await tester.pumpWidget(
        localizedTestApp(home: GlazeNotebookPage(tiles: tiles)),
      );
      await tester.pumpAndSettle();
      expect(find.text('No saved records yet.'), findsOneWidget);
      await tester.tap(
        find.byTooltip(tiles ? 'Create test tile' : 'Create combination'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlazeNotebookEditorPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  test(
    'initial notebook loads omit unset cursor and filter query values',
    () async {
      final adapter = NotebookListAdapter();
      ApiClient.dio = Dio(
        BaseOptions(baseUrl: 'http://localhost', validateStatus: (_) => true),
      )..httpClientAdapter = adapter;
      for (final tiles in [false, true]) {
        final controller = GlazeNotebookController(tiles: tiles);
        await controller.load();
        expect(controller.failed, isFalse);
        expect(controller.items, isEmpty);
        controller.dispose();
      }
      final initialRequests = [...adapter.requests];
      expect(initialRequests, isNotEmpty);
      for (final request in initialRequests) {
        expect(request.uri.queryParameters.containsKey('cursor'), isFalse);
        expect(request.uri.queryParameters.containsKey('recipeId'), isFalse);
        expect(request.uri.queryParameters.containsKey('clayId'), isFalse);
      }
      await GlazeNotebookRepository(
        tiles: true,
      ).list(cursor: '12', recipeId: 4, clayId: 2);
      expect(
        adapter.requests.last.uri.queryParameters,
        containsPair('cursor', '12'),
      );
      expect(
        adapter.requests.last.uri.queryParameters,
        containsPair('recipeId', '4'),
      );
      expect(
        adapter.requests.last.uri.queryParameters,
        containsPair('clayId', '2'),
      );
    },
  );
  test(
    'tile draft makes independent layers and retains source version and Celsius',
    () {
      final source = recipe();
      final tile = source.tileDraft();
      tile.layers.first.note = 'Actual';
      tile.firings.first.firing.targetTemperatureC = 1210;
      expect(source.layers.first.note, 'Rim');
      expect(source.firings.first.firing.targetTemperatureC, 1200);
      expect(tile.layers.first.id, isNull);
      expect(tile.sourceVersion, 8);
      expect(tile.toRequestJson()['expectedCombinationVersion'], 8);
      expect(tile.firings.first.atmosphere, 'REDUCTION');
    },
  );
  test(
    'piece creation appends unique local drafts and preserves unrelated fields',
    () async {
      final c = CeramicCreatePageController();
      c.title = 'Keep';
      c.clayTypeId = 22;
      c.notes = 'Private';
      c.glazes = [
        CeramicGlazeEntryDto(
          id: 9,
          glazeId: 2,
          ceramicId: 0,
          note: 'Keep',
          layerOrder: 7,
        ),
      ];
      expect(await c.appendCombination(recipe()), isTrue);
      expect(c.glazes.map((l) => l.id), [9, 10, 11]);
      expect(c.glazes.map((l) => l.layerOrder), [7, 8, 9]);
      expect(c.title, 'Keep');
      expect(c.clayTypeId, 22);
      expect(c.notes, 'Private');
      c.dispose();
    },
  );
  test(
    'lost response and refresh failures retain identity until confirmed success',
    () async {
      final adapter = NotebookAdapter()..failApply = true;
      ApiClient.dio = Dio()..httpClientAdapter = adapter;
      final c = CombinationApplicationController();
      c.begin(recipe(), 5);
      final id = c.requestId;
      expect(await c.apply(() async {}), isFalse);
      expect(c.requestId, id);
      expect(CombinationApplicationController.forPiece(5), same(c));
      expect(CombinationApplicationController.forRecipe(4), same(c));
      adapter.failApply = false;
      expect(
        await c.apply(() async {
          throw StateError('Refresh failed');
        }),
        isFalse,
      );
      expect(c.requestId, id);
      bool refreshed = false;
      expect(
        await c.apply(() async {
          refreshed = true;
        }),
        isTrue,
      );
      expect(refreshed, isTrue);
      expect(
        adapter.requests
            .where((r) => r.path.endsWith('/apply'))
            .map((r) => r.data['clientRequestId']),
        [id, id, id],
      );
      c.begin(recipe(), 5);
      expect(c.requestId, isNot(id));
    },
  );
  test(
    'API envelope conflicts allow deliberate reload and a fresh application',
    () async {
      final adapter = NotebookAdapter()..conflict = true;
      ApiClient.dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = adapter;
      final c = CombinationApplicationController();
      c.begin(recipe(), 5);
      final id = c.requestId;
      expect(await c.apply(() async {}), isFalse);
      expect(c.conflict, isTrue);
      expect(c.pending, isNull);
      c.begin(recipe(), 5);
      expect(c.requestId, isNot(id));
    },
  );
  testWidgets('failed save retains draft and reports version conflict', (
    tester,
  ) async {
    ApiClient.dio = Dio(BaseOptions(validateStatus: (_) => true))
      ..httpClientAdapter = (NotebookAdapter()..conflict = true);
    final c = GlazeNotebookController(tiles: false)
      ..glazes = [GlazeDto(id: 1, title: 'Blue')];
    await tester.pumpWidget(
      localizedTestApp(
        home: GlazeNotebookEditorPage(controller: c, value: recipe()),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Edited draft');
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Edited draft'), findsOneWidget);
    expect(find.textContaining('This record changed.'), findsOneWidget);
    expect(find.byType(GlazeNotebookEditorPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('typing immediately protects an unsaved draft on back', (
    tester,
  ) async {
    final c = GlazeNotebookController(tiles: false);
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GlazeNotebookEditorPage(controller: c),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Keep draft');
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Keep draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'compact layer editor shows saved missing-glaze names and accessible reorder',
    (tester) async {
      tester.view.physicalSize = const Size(280, 620);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GlazeApplicationEditor(
                entries: [
                  NotebookLayerDto(glazeTitle: 'Deleted blue').entry(1, 1),
                ],
                glazes: const [],
                entryNames: const {1: 'Deleted blue'},
                onAdd: (_) async => true,
                onDelete: (_) async => true,
                onMove: (_, _) async => true,
                onEdit: (_, _, _) async => true,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Deleted blue'), findsOneWidget);
      expect(find.byTooltip('Move down'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'notebook creation labels are Danish and no custom-count gate blocks unchanged notes',
    (tester) async {
      final c = GlazeNotebookController(tiles: true)
        ..glazes = [GlazeDto(id: 1, title: 'Blue')];
      await tester.pumpWidget(
        localizedTestApp(
          locale: const Locale('da'),
          home: GlazeNotebookEditorPage(
            controller: c,
            value: recipe().tileDraft(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Opret prøveflise'), findsOneWidget);
      expect(find.text('Faktiske forhold'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'recipe firing editor shows planning and atmosphere without completed controls',
    (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: FiringEditorDialog(
              ceramicId: 0,
              planningOnly: true,
              showAtmosphere: true,
              onSave: (_) async => true,
            ),
          ),
        ),
      );
      expect(find.text('Atmosphere'), findsOneWidget);
      expect(find.text('Completed'), findsNothing);
      expect(find.text('Peak temperature'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'preview presents existing followed by copied layers and appends only on confirmation',
    (tester) async {
      int applied = 0;
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => previewCombination(
                  context,
                  recipe: recipe(),
                  existing: [
                    CeramicGlazeEntryDto(
                      id: 1,
                      glazeId: 2,
                      ceramicId: 5,
                      note: '',
                      layerOrder: 7,
                    ),
                  ],
                  glazes: [GlazeDto(id: 2, title: 'Existing')],
                  onApply: () async {
                    applied++;
                    return true;
                  },
                ),
                child: const Text('Preview'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1. Existing'), findsOneWidget);
      expect(find.textContaining('2. Blue'), findsOneWidget);
      expect(applied, 0);
      await tester.tap(find.text('Apply saved combination'));
      await tester.pumpAndSettle();
      expect(applied, 1);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}

class NotebookAdapter implements HttpClientAdapter {
  bool failApply = false, conflict = false;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (failApply && options.path.endsWith('/apply')) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(
        conflict
            ? {
                'success': false,
                'error': {'message': 'Changed', 'code': 'CONFLICT'},
              }
            : {'success': true, 'data': {}},
      ),
      conflict ? 409 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class NotebookListAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final notebook =
        options.path == '/api/glaze-combinations' ||
        options.path == '/api/test-tiles';
    if (notebook) requests.add(options);
    final cursor = options.uri.queryParameters['cursor'];
    final invalidCursor = cursor != null && int.tryParse(cursor) == null;
    return ResponseBody.fromString(
      jsonEncode(
        invalidCursor
            ? {
                'success': false,
                'error': {'message': 'Invalid cursor', 'code': 'VALIDATION'},
              }
            : {
                'success': true,
                'data': notebook ? {'items': [], 'nextCursor': null} : [],
              },
      ),
      invalidCursor ? 400 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
