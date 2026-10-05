import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/glaze_dto.dart';
import 'package:clay_dock/objects/glaze_notebook_dto.dart';
import 'package:clay_dock/ui/pages/materials/glazes/glazes_create/glazes_create_page.dart';
import 'package:clay_dock/ui/pages/materials/glazes/glazes_view/glazes_view_page.dart';
import 'package:clay_dock/ui/pages/materials/glazes/notebook/glaze_notebook_controller.dart';
import 'package:clay_dock/ui/pages/materials/glazes/notebook/glaze_notebook_detail_page.dart';
import 'package:clay_dock/ui/widgets/v2/ui_library.dart';
import 'package:clay_dock/ui/widgets/v2/dropdown_widget.dart';
import 'test_app.dart';

void main() {
  testWidgets('legacy dropdown reverts a rejected asynchronous selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: DropdownWidget(
            initialValue: 'blue',
            entries: const [MapEntry('Blue', 'blue'), MapEntry('Red', 'red')],
            onChanged: (_) async => false,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red').last);
    await tester.pumpAndSettle();
    final field = tester.state<FormFieldState<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(field.value, 'blue');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'caller-owned text controller survives validation and field removal',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final controller = TextEditingController();
        final form = GlobalKey<FormState>();
        await tester.pumpWidget(
          localizedTestApp(
            home: Scaffold(
              body: Form(
                key: form,
                child: TextFieldWidget(
                  controller: controller,
                  label: 'Name',
                  validator: (value, _) => value!.isEmpty ? 'Required' : null,
                ),
              ),
            ),
          ),
        );
        expect(form.currentState!.validate(), isFalse);
        await tester.pump();
        expect(find.text('Required'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), 'My draft');
        await tester.pump();
        expect(
          tester.getSemantics(find.byType(TextFormField)).label,
          contains('Name'),
        );
        expect(form.currentState!.validate(), isTrue);
        await tester.pumpWidget(const SizedBox());
        controller.text = 'Still owned by caller';
        expect(controller.text, 'Still owned by caller');
        controller.dispose();
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('existing async accept/revert callbacks remain supported', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: TextFieldWidget(
            initialValue: 'Saved',
            onChanged: (_) async => false,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'Rejected');
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Rejected'), findsNothing);
  });

  testWidgets(
    'glaze edit writes on Save, retains failed draft, then refreshes detail',
    (tester) async {
      final adapter = GlazeUiAdapter();
      ApiClient.dio = Dio(
        BaseOptions(baseUrl: 'http://localhost', validateStatus: (_) => true),
      )..httpClientAdapter = adapter;
      await tester.pumpWidget(
        localizedTestApp(
          home: GlazesViewPage(glaze: GlazeDto(id: 3, title: 'Blue')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EntryPage), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Changed blue');
      await tester.pump(const Duration(milliseconds: 500));
      expect(adapter.writes, isEmpty);
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(GlazesCreatePage), findsOneWidget);
      expect(find.text('Changed blue'), findsOneWidget);
      expect(find.textContaining('Your draft is preserved.'), findsOneWidget);
      adapter.fail = false;
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(adapter.writes, ['Changed blue', 'Changed blue']);
      expect(find.byType(GlazesCreatePage), findsNothing);
      expect(find.widgetWithText(EntryValue, 'Changed blue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'glaze Back/Cancel preserves draft and required-name validation prevents writing',
    (tester) async {
      final adapter = GlazeUiAdapter();
      ApiClient.dio = Dio(
        BaseOptions(baseUrl: 'http://localhost', validateStatus: (_) => true),
      )..httpClientAdapter = adapter;
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GlazesCreatePage()),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a title up to 255 characters'), findsOneWidget);
      expect(adapter.writes, isEmpty);
      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(find.byType(GlazesCreatePage), findsNothing);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Keep me');
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Keep me'), findsOneWidget);
      expect(adapter.writes, isEmpty);
    },
  );

  for (final locale in [const Locale('en'), const Locale('da')]) {
    testWidgets(
      'material and tile detail use the same shell at compact enlarged text: $locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final notebook = GlazeNotebookController(tiles: true);
        final pages = <Widget>[
          GlazesViewPage(
            glaze: GlazeDto(id: 3, title: 'A glaze with a long readable title'),
          ),
          GlazeNotebookDetailPage(
            controller: notebook,
            value: GlazeNotebookDto(
              id: 5,
              name: 'A tile with a long readable title',
              notes: 'Result details',
              layers: [],
              firings: [],
            ),
          ),
        ];
        for (final page in pages) {
          await tester.pumpWidget(
            localizedTestApp(
              locale: locale,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 568),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: page,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(EntryPage), findsOneWidget);
          expect(find.byType(EntrySection), findsWidgets);
          expect(find.byType(EntryValue), findsWidgets);
          expect(find.byType(TextFormField), findsNothing);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        notebook.dispose();
      },
    );
  }
}

class GlazeUiAdapter implements HttpClientAdapter {
  bool fail = true;
  String title = 'Blue';
  final writes = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'PUT' || options.method == 'POST') {
      final value = (options.data as Map)['title'] as String;
      writes.add(value);
      if (!fail) title = value;
    }
    final rejected = fail && options.method != 'GET';
    return ResponseBody.fromString(
      jsonEncode(
        rejected
            ? {
                'success': false,
                'error': {'message': 'Retry', 'code': 'VALIDATION'},
              }
            : {
                'success': true,
                'data': {'id': 3, 'title': title},
              },
      ),
      rejected ? 400 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
