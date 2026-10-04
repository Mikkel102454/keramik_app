import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show SemanticsAction;

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/ui/pages/discover/discover_controller.dart';
import 'package:ceramic_app/ui/pages/discover/discover_page.dart';
import 'package:ceramic_app/ui/theme/studio_theme.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Root badge refresh remains local; feed operations use injected callbacks.
    ApiClient.dio = Dio()..httpClientAdapter = _BadgeAdapter();
  });

  testWidgets('creator avatar exposes one actionable username', (tester) async {
    _viewport(tester, const Size(384, 832));
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _app(
          forYou: _controller('FOR_YOU', count: 1),
          latest: _controller('LATEST', count: 1),
        ),
      );
      await tester.pumpAndSettle();
      final avatar = _action('FOR_YOU', 'potter_for_you_0');
      expect(avatar, findsOneWidget);
      final node = tester.getSemantics(avatar);
      expect(node.tooltip, 'potter_for_you_0');
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(find.bySemanticsLabel('PO'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'Discover follows appearance changes without losing the visible post',
    (tester) async {
      _viewport(tester, const Size(384, 832));
      final forYou = _controller('FOR_YOU', count: 3);
      final latest = _controller('LATEST', count: 3);
      await tester.pumpWidget(_app(forYou: forYou, latest: latest));
      await tester.pumpAndSettle();
      await _nextPage(tester, 'FOR_YOU');
      for (final dark in [true, false]) {
        await tester.pumpWidget(
          _app(forYou: forYou, latest: latest, dark: dark),
        );
        await tester.pumpAndSettle();
        final theme = Theme.of(tester.element(_feed('FOR_YOU')));
        expect(theme.brightness, dark ? Brightness.dark : Brightness.light);
        expect(_page(tester, 'FOR_YOU'), closeTo(1, .001));
        expect(_action('FOR_YOU', 'potter_for_you_1'), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(NavigationWidget))).brightness,
          theme.brightness,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'vertical feeds retain independent positions across tabs and likes',
    (tester) async {
      _viewport(tester, const Size(384, 832));
      final likedIds = <String>[];
      final forYou = _controller('FOR_YOU', count: 4, likedIds: likedIds);
      final latest = _controller('LATEST', count: 4);
      await tester.pumpWidget(_app(forYou: forYou, latest: latest));
      await tester.pumpAndSettle();

      expect(_page(tester, 'FOR_YOU'), closeTo(0, .001));
      await _nextPage(tester, 'FOR_YOU');
      expect(_page(tester, 'FOR_YOU'), closeTo(1, .001));
      await tester.tap(_action('FOR_YOU', 'Like'));
      await tester.pumpAndSettle();
      expect(likedIds, ['FOR_YOU-1']);
      expect(forYou.items[1].likedByMe, isTrue);
      expect(_page(tester, 'FOR_YOU'), closeTo(1, .001));

      await tester.tap(find.text('Latest'));
      await tester.pumpAndSettle();
      expect(_page(tester, 'LATEST'), closeTo(0, .001));
      await _nextPage(tester, 'LATEST');
      await _nextPage(tester, 'LATEST');
      expect(_page(tester, 'LATEST'), closeTo(2, .001));
      await tester.tap(find.text('For You'));
      await tester.pumpAndSettle();
      expect(_page(tester, 'FOR_YOU'), closeTo(1, .001));
      await tester.tap(find.text('Latest'));
      await tester.pumpAndSettle();
      expect(_page(tester, 'LATEST'), closeTo(2, .001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hiding the current post and Undo keep the pager valid', (
    tester,
  ) async {
    _viewport(tester, const Size(384, 832));
    final hidden = <(String, bool)>[];
    final likedIds = <String>[];
    final forYou = _controller(
      'FOR_YOU',
      count: 3,
      likedIds: likedIds,
      hideUpdater: (id, value) async => hidden.add((id, value)),
    );
    final latest = _controller('LATEST', count: 1);
    await tester.pumpWidget(_app(forYou: forYou, latest: latest));
    await tester.pumpAndSettle();
    await _nextPage(tester, 'FOR_YOU');
    await _hideCurrent(tester, 'FOR_YOU');

    expect(hidden, [('FOR_YOU-1', true)]);
    expect(forYou.items.map((item) => item.publicationId), [
      'FOR_YOU-0',
      'FOR_YOU-2',
    ]);
    expect(_page(tester, 'FOR_YOU'), closeTo(1, .001));
    await tester.tap(_action('FOR_YOU', 'Like'));
    await tester.pumpAndSettle();
    expect(likedIds, ['FOR_YOU-2']);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(hidden, [('FOR_YOU-1', true), ('FOR_YOU-1', false)]);
    expect(forYou.items.map((item) => item.publicationId), [
      'FOR_YOU-0',
      'FOR_YOU-1',
      'FOR_YOU-2',
    ]);
    expect(_page(tester, 'FOR_YOU'), inInclusiveRange(0, 2));
    await tester.tap(_action('FOR_YOU', 'Like'));
    await tester.pumpAndSettle();
    expect(likedIds, ['FOR_YOU-2', 'FOR_YOU-2']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed hide restores the post without exposing technical details',
    (tester) async {
      _viewport(tester, const Size(384, 832));
      final pending = Completer<void>();
      final forYou = _controller(
        'FOR_YOU',
        count: 3,
        hideUpdater: (_, _) => pending.future,
      );
      final latest = _controller('LATEST', count: 1);
      await tester.pumpWidget(_app(forYou: forYou, latest: latest));
      await tester.pumpAndSettle();
      await _nextPage(tester, 'FOR_YOU');
      await tester.tap(_menu('FOR_YOU'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not interested').last);
      await tester.pump();
      expect(forYou.items.map((item) => item.publicationId), [
        'FOR_YOU-0',
        'FOR_YOU-2',
      ]);

      pending.completeError(Exception('private transport detail'));
      await tester.pumpAndSettle();
      expect(forYou.items.map((item) => item.publicationId), [
        'FOR_YOU-0',
        'FOR_YOU-1',
        'FOR_YOU-2',
      ]);
      expect(find.text('private transport detail'), findsNothing);
      expect(
        find.text('That action could not be completed. Please try again.'),
        findsOneWidget,
      );
      expect(_page(tester, 'FOR_YOU'), inInclusiveRange(0, 2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hiding the last page clamps to an available post', (
    tester,
  ) async {
    _viewport(tester, const Size(384, 832));
    final forYou = _controller('FOR_YOU', count: 3);
    final latest = _controller('LATEST', count: 1);
    await tester.pumpWidget(_app(forYou: forYou, latest: latest));
    await tester.pumpAndSettle();
    await _nextPage(tester, 'FOR_YOU');
    await _nextPage(tester, 'FOR_YOU');
    expect(_page(tester, 'FOR_YOU'), closeTo(2, .001));
    await _hideCurrent(tester, 'FOR_YOU');
    expect(forYou.items, hasLength(2));
    expect(_page(tester, 'FOR_YOU'), closeTo(1, .001));
    expect(_action('FOR_YOU', 'Like').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final size in [
      const Size(320, 568),
      const Size(384, 832),
      const Size(800, 384),
      const Size(1280, 800),
    ]) {
      testWidgets(
        'feed actions remain reachable at $size with 2x text, system insets and ${dark ? 'dark' : 'light'} app theme',
        (tester) async {
          _viewport(tester, size);
          final forYou = _controller('FOR_YOU', count: 3, longText: true);
          final latest = _controller('LATEST', count: 1);
          await tester.pumpWidget(
            _app(forYou: forYou, latest: latest, dark: dark, scale: 2),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final feedRect = tester.getRect(_feed('FOR_YOU'));
          expect(feedRect.top, greaterThanOrEqualTo(24));
          expect(feedRect.bottom, lessThanOrEqualTo(size.height - 48));
          expect(
            Theme.of(tester.element(_feed('FOR_YOU'))).brightness,
            dark ? Brightness.dark : Brightness.light,
          );

          for (final tooltip in ['Like', 'Share', 'Information']) {
            await tester.ensureVisible(_rawAction('FOR_YOU', tooltip));
            await tester.pumpAndSettle();
            final action = _action('FOR_YOU', tooltip).hitTestable();
            expect(action, findsOneWidget);
            final rect = tester.getRect(action);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.top, greaterThanOrEqualTo(feedRect.top));
            expect(rect.bottom, lessThanOrEqualTo(feedRect.bottom));
          }
          await tester.ensureVisible(_rawMenu('FOR_YOU'));
          await tester.pumpAndSettle();
          final menu = _menu('FOR_YOU').hitTestable();
          expect(menu, findsOneWidget);
          expect(
            tester.getRect(menu).size.shortestSide,
            greaterThanOrEqualTo(48),
          );
          final nav = find.byType(NavigationWidget);
          expect(
            find.descendant(of: nav, matching: find.byTooltip('Discover')),
            findsOneWidget,
          );
          expect(find.text('Latest').hitTestable(), findsOneWidget);
          await _nextPage(tester, 'FOR_YOU');
          expect(_page(tester, 'FOR_YOU'), closeTo(1, .001));
          await tester.ensureVisible(_rawAction('FOR_YOU', 'Like'));
          await tester.pumpAndSettle();
          expect(_action('FOR_YOU', 'Like').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

DiscoverController _controller(
  String mode, {
  required int count,
  bool longText = false,
  List<String>? likedIds,
  NotInterestedUpdater? hideUpdater,
}) {
  final controller = DiscoverController(
    mode,
    pageLoader: (_, {cursor, requestId}) async => DiscoverPageDto([
      for (var index = 0; index < count; index++)
        _card(mode, index, longText: longText),
    ], null),
    likeUpdater: (card, liked) async {
      likedIds?.add(card.publicationId);
      return card.copyWith(
        likedByMe: liked,
        likeCount: card.likeCount + (liked ? 1 : -1),
      );
    },
    notInterestedUpdater: hideUpdater ?? (_, _) async {},
  );
  addTearDown(controller.dispose);
  return controller;
}

PublicationCardDto _card(
  String mode,
  int index, {
  bool longText = false,
}) => PublicationCardDto(
  publicationId: '$mode-$index',
  creator: PublicationCreatorDto(
    userId: '$mode-creator-$index',
    username: longText
        ? 'potter_with_a_long_public_username_$index'
        : 'potter_${mode.toLowerCase()}_$index',
    avatarInitials: 'PO',
    avatarColor: '#355070',
  ),
  title: longText
      ? 'Handbuilt studio bowl $index with an exceptionally long title describing its form, clay body and layered glaze observations for the next firing.'
      : '$mode bowl $index',
  clay: longText
      ? 'A long stoneware clay body name with supplier details'
      : 'Stoneware',
  likeCount: 4,
  likedByMe: false,
  ownedByMe: false,
  publishedAt: DateTime.utc(2026, 10, 4),
);

Finder _feed(String mode) => find.byKey(ValueKey('discover-feed-$mode'));

Finder _rawAction(String mode, String tooltip) =>
    find.descendant(of: _feed(mode), matching: find.byTooltip(tooltip));

Finder _action(String mode, String tooltip) =>
    _rawAction(mode, tooltip).hitTestable();

Finder _rawMenu(String mode) => find.descendant(
  of: _feed(mode),
  matching: find.byType(PopupMenuButton<String>),
);

Finder _menu(String mode) => _rawMenu(mode).hitTestable();

double _page(WidgetTester tester, String mode) =>
    tester.widget<PageView>(_feed(mode)).controller!.page!;

Future<void> _nextPage(WidgetTester tester, String mode) async {
  final rect = tester.getRect(_feed(mode));
  // Start above the caption so the gesture pages the photo rather than its text.
  await tester.dragFrom(
    Offset(rect.center.dx, rect.top + rect.height * .2),
    Offset(0, -rect.height * .72),
  );
  await tester.pumpAndSettle();
}

Future<void> _hideCurrent(WidgetTester tester, String mode) async {
  await tester.tap(_menu(mode));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Not interested').last);
  await tester.pumpAndSettle();
}

Widget _app({
  required DiscoverController forYou,
  required DiscoverController latest,
  bool dark = false,
  double scale = 1,
}) => MaterialApp(
  theme: dark ? StudioTheme.dark() : StudioTheme.light(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: DiscoverPage(forYouController: forYou, latestController: latest),
);

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
  addTearDown(tester.view.reset);
}

class _BadgeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/api/chat/badge') {
      throw StateError('Unexpected non-fixture API operation');
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'count': 0},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
