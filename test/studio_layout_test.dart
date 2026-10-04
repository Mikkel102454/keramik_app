import 'dart:convert';
import 'dart:typed_data';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/config/router/app_router.dart';
import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/main.dart';
import 'package:ceramic_app/ui/pages/home/home_page.dart';
import 'package:ceramic_app/ui/pages/materials/materials_page.dart';
import 'package:ceramic_app/ui/theme/studio_theme.dart';
import 'package:ceramic_app/ui/widgets/ceramic_journal_card.dart';
import 'package:ceramic_app/ui/widgets/v2/entry_page_widgets.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/studio_widgets.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _StudioAdapter adapter;
  setUp(() {
    adapter = _StudioAdapter();
    ApiClient.dio = Dio()..httpClientAdapter = adapter;
  });

  for (final dark in [false, true]) {
    final theme = dark ? StudioTheme.dark() : StudioTheme.light();
    test(
      'studio ${dark ? 'dark' : 'light'} text retains readable contrast',
      () {
        final colors = theme.colorScheme;
        for (final pair in [
          (colors.onSurface, colors.surface),
          (colors.onSurfaceVariant, colors.surfaceContainerLowest),
          (colors.onPrimary, colors.primary),
          (colors.onPrimaryContainer, colors.primaryContainer),
          (colors.onTertiary, colors.tertiary),
          (colors.onTertiaryContainer, colors.tertiaryContainer),
          (colors.onError, colors.error),
        ]) {
          final a = pair.$1.computeLuminance();
          final b = pair.$2.computeLuminance();
          final contrast = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
          expect(contrast, greaterThanOrEqualTo(4.5));
        }
        expect(theme.useMaterial3, isTrue);
        expect(
          colors.surface,
          dark ? const Color(0xff0c0c0e) : const Color(0xffffffff),
        );
      },
    );

    for (final width in [320.0, 384.0, 800.0, 1280.0]) {
      testWidgets(
        'materials at $width in ${dark ? 'dark' : 'light'} stays usable with enlarged text and system navigation',
        (tester) async {
          _viewport(tester, Size(width, 832));
          await tester.pumpWidget(
            _app(theme: theme, scale: 2, home: const MaterialsPage()),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final navigation = tester.widget<NavigationWidget>(
            find.byType(NavigationWidget),
          );
          expect(navigation.vertical, width >= 840);
          final clays = find.text('Clays');
          expect(clays, findsOneWidget);
          await tester.ensureVisible(clays);
          expect(tester.getRect(clays).bottom, lessThanOrEqualTo(784));
          if (width < 840) {
            final nav = find.byType(NavigationWidget);
            final profile = find.descendant(
              of: nav,
              matching: find.byTooltip('Profile'),
            );
            expect(profile, findsOneWidget);
            expect(tester.getRect(profile).bottom, lessThanOrEqualTo(784));
            for (final label in [
              'Home',
              'Materials',
              'Discover',
              'Chats',
              'Profile',
            ]) {
              expect(
                find.descendant(of: nav, matching: find.byTooltip(label)),
                findsOneWidget,
              );
            }
            for (final text
                in find
                    .descendant(of: nav, matching: find.byType(Text))
                    .evaluate()) {
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(
                  of: find.byElementPredicate((element) => element == text),
                  matching: find.byType(RichText),
                ),
              );
              expect(paragraph.didExceedMaxLines, isFalse);
            }
          }
        },
      );
    }

    testWidgets(
      'entry fields and save stay reachable with keyboard in ${dark ? 'dark' : 'light'}',
      (tester) async {
        _viewport(tester, const Size(320, 568));
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        addTearDown(tester.view.resetViewInsets);
        final draft = TextEditingController();
        addTearDown(draft.dispose);
        var saves = 0;
        await tester.pumpWidget(
          _app(
            theme: theme,
            scale: 2,
            home: EntryPage(
              title: 'Edit test tile',
              onSave: () => saves++,
              children: [
                EntrySection(
                  title: 'Information',
                  children: [
                    const EntryValue(
                      label: 'Source recipe',
                      value: 'Ocean layers',
                    ),
                    TextFieldWidget(
                      controller: draft,
                      label: 'Result notes',
                      maxLines: 3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = find.byType(TextFormField);
        await tester.ensureVisible(field);
        await tester.enterText(field, 'A useful result retained in the draft');
        await tester.pump();
        expect(draft.text, 'A useful result retained in the draft');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Save'));
        await tester.pump();
        expect(saves, 1);
        expect(tester.getRect(find.byTooltip('Save')).bottom, lessThan(328));
      },
    );

    testWidgets(
      'compact ${dark ? 'dark' : 'light'} journal preview retains accessible metadata and action',
      (tester) async {
        _viewport(tester, const Size(320, 568));
        var opened = 0;
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _app(
              theme: theme,
              scale: 2,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 132,
                    height: 340,
                    child: CeramicJournalCard.public(
                      publicTitle: 'A hand-thrown bowl with a long title',
                      publicRating: 4,
                      publicImageUrl: null,
                      stageTitle: 'Finished',
                      clayTitle: 'Speckled stoneware',
                      onTap: () => opened++,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('A hand-thrown bowl with a long title'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(
              'A hand-thrown bowl with a long title, Speckled stoneware, Finished, Rating: 4',
            ),
            findsOneWidget,
          );
          expect(find.text('Finished'), findsOneWidget);
          expect(find.text('Speckled stoneware'), findsOneWidget);
          expect(find.text('4'), findsOneWidget);
          expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
          await tester.tap(find.byType(CeramicJournalCard));
          await tester.pump();
          expect(opened, 1);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'compact enlarged journal error keeps retry and empty action reachable',
    (tester) async {
      _viewport(tester, const Size(320, 568));
      adapter.failJournal = true;
      await tester.pumpWidget(
        _app(theme: StudioTheme.light(), scale: 2, home: const HomePage()),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('We could not load your ceramic journal.'),
        findsOneWidget,
      );
      adapter.failJournal = false;
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Create your first piece'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Start your ceramic journal'), findsOneWidget);
      expect(find.text('Create your first piece'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(
        tester
            .widget<SliverFillRemaining>(find.byType(SliverFillRemaining))
            .hasScrollBody,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all root destinations remain reachable through the existing router',
    (tester) async {
      _viewport(tester, const Size(384, 832));
      final authentication = AuthenticationCubit(
        dio: ApiClient.dio,
        cookieJar: PersistCookieJar(persistSession: false),
      );
      addTearDown(authentication.close);
      final router = AppRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider.value(
          value: authentication,
          child: MyApp(appRouter: router),
        ),
      );
      await tester.pumpAndSettle();
      router.replace(const MaterialsRoute());
      await tester.pumpAndSettle();
      for (final destination in [
        ('Home', HomeRoute.name),
        ('Discover', ShopRoute.name),
        ('Chats', NotificationRoute.name),
        ('Profile', ProfileRoute.name),
        ('Materials', MaterialsRoute.name),
      ]) {
        await tester.tap(find.byTooltip(destination.$1));
        await tester.pumpAndSettle();
        expect(router.current.name, destination.$2);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('very narrow navigation keeps the full selected label visible', (
    tester,
  ) async {
    _viewport(tester, const Size(240, 568));
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _app(
          theme: StudioTheme.dark(),
          scale: 3,
          home: const Scaffold(
            bottomNavigationBar: NavigationWidget(
              currentPage: NavigationPage.profile,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final profile = find.text('Profile');
      expect(tester.getRect(profile).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(profile).right, lessThanOrEqualTo(240));
      expect(tester.getSemantics(find.byTooltip('Profile')).label, 'Profile');
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('wide forms stay centered within the shared reading width', (
    tester,
  ) async {
    _viewport(tester, const Size(1440, 900));
    const contentKey = Key('form-content');
    await tester.pumpWidget(
      _app(
        theme: StudioTheme.light(),
        home: const EntryPage(
          title: 'Recipe',
          children: [
            SizedBox(key: contentKey, height: 100, width: double.infinity),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(contentKey));
    expect(rect.width, lessThanOrEqualTo(StudioSpacing.formWidth));
    expect(rect.center.dx, closeTo(720, 1));
    expect(tester.takeException(), isNull);
  });
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

Widget _app({
  required ThemeData theme,
  required Widget home,
  double scale = 1,
}) => MaterialApp(
  theme: theme,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

class _StudioAdapter implements HttpClientAdapter {
  bool failJournal = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (failJournal && options.path == '/api/ceramics') {
      return _response({
        'success': false,
        'error': {'code': 'INTERNAL_ERROR'},
      }, 500);
    }
    final Object data = switch (options.path) {
      '/api/stages' => [
        {'id': 1, 'title': 'Ideas'},
      ],
      '/api/chat/badge' => {'count': 0},
      '/api/chat/conversations' ||
      '/api/social/friends' ||
      '/api/social/friend-requests/incoming' ||
      '/api/social/friend-requests/outgoing' ||
      '/api/chat/requests/incoming' ||
      '/api/chat/requests/outgoing' => {'items': [], 'nextCursor': null},
      _ => [],
    };
    return _response({'success': true, 'data': data}, 200);
  }

  ResponseBody _response(Map<String, dynamic> value, int status) =>
      ResponseBody.fromString(
        jsonEncode(value),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
