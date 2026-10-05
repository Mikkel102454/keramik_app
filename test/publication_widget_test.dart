import 'dart:async';

import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/objects/publication_dto.dart';
import 'package:clay_dock/ui/pages/discover/discover_controller.dart';
import 'package:clay_dock/ui/pages/discover/discover_page.dart';
import 'package:clay_dock/ui/pages/discover/publication_detail_page.dart';
import 'package:clay_dock/ui/pages/v2/pages.dart';
import 'package:clay_dock/ui/widgets/chat_publication_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets(
    'failed Discover refresh retains cards and retries without a cursor',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final requestIds = <String?>[];
      final cursors = <String?>[];
      final forYou = DiscoverController(
        'FOR_YOU',
        pageLoader: (_, {cursor, requestId}) async {
          requestIds.add(requestId);
          cursors.add(cursor);
          if (requestIds.length == 2) {
            throw Exception('private refresh detail');
          }
          return DiscoverPageDto([_card()], null);
        },
      );
      final latest = DiscoverController(
        'LATEST',
        pageLoader: (_, {cursor, requestId}) async =>
            const DiscoverPageDto([], null),
      );
      addTearDown(forYou.dispose);
      addTearDown(latest.dispose);
      await tester.pumpWidget(
        localizedTestApp(
          home: DiscoverPage(
            forYouController: forYou,
            latestController: latest,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(forYou.nextCursor, isNull);
      await tester.drag(
        find.byKey(const ValueKey('discover-feed-FOR_YOU')),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();
      expect(requestIds, hasLength(2));
      expect(forYou.items.single.title, 'Published bowl');
      expect(find.text('potter'), findsOneWidget);
      expect(find.text('Ceramics could not be loaded.'), findsOneWidget);
      expect(find.text('private refresh detail'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(requestIds, hasLength(2));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(requestIds, hasLength(3));
      expect(requestIds[2], requestIds[1]);
      expect(cursors, everyElement(isNull));
      expect(forYou.items.single.title, 'Published bowl');
      expect(find.text('Retry'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed Discover pagination keeps cards and waits for explicit retry',
    (tester) async {
      final requestIds = <String?>[];
      final forYou = DiscoverController(
        'FOR_YOU',
        pageLoader: (_, {cursor, requestId}) async {
          requestIds.add(requestId);
          if (requestIds.length == 1) return DiscoverPageDto([_card()], 'next');
          if (requestIds.length == 2) {
            throw Exception('private pagination detail');
          }
          return const DiscoverPageDto([], null);
        },
      );
      final latest = DiscoverController(
        'LATEST',
        pageLoader: (_, {cursor, requestId}) async =>
            const DiscoverPageDto([], null),
      );
      addTearDown(forYou.dispose);
      addTearDown(latest.dispose);
      await tester.pumpWidget(
        localizedTestApp(
          home: DiscoverPage(
            forYouController: forYou,
            latestController: latest,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('discover-feed-FOR_YOU')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(requestIds, hasLength(2));
      expect(forYou.items.single.title, 'Published bowl');
      expect(find.text('private pagination detail'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(requestIds, hasLength(2));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(requestIds, hasLength(3));
      expect(requestIds[2], requestIds[1]);
      expect(forYou.items.single.title, 'Published bowl');
      expect(find.text('Retry'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed hide restores its card and displays safe feedback', (
    tester,
  ) async {
    final forYou = DiscoverController(
      'FOR_YOU',
      pageLoader: (_, {cursor, requestId}) async =>
          DiscoverPageDto([_card()], null),
      notInterestedUpdater: (_, _) async =>
          throw Exception('private action detail'),
    );
    final latest = DiscoverController(
      'LATEST',
      pageLoader: (_, {cursor, requestId}) async =>
          const DiscoverPageDto([], null),
    );
    addTearDown(forYou.dispose);
    addTearDown(latest.dispose);
    await tester.pumpWidget(
      localizedTestApp(
        home: DiscoverPage(forYouController: forYou, latestController: latest),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not interested').last);
    await tester.pumpAndSettle();
    expect(forYou.items.single.title, 'Published bowl');
    expect(
      find.text('That action could not be completed. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('private action detail'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop route page opens Discover', (tester) async {
    final forYou = DiscoverController(
      'FOR_YOU',
      pageLoader: (_, {cursor, requestId}) async =>
          const DiscoverPageDto([], null),
    );
    final latest = DiscoverController(
      'LATEST',
      pageLoader: (_, {cursor, requestId}) async =>
          const DiscoverPageDto([], null),
    );
    addTearDown(forYou.dispose);
    addTearDown(latest.dispose);

    await tester.pumpWidget(
      localizedTestApp(
        home: ShopPage(forYouController: forYou, latestController: latest),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('For You')),
      findsOneWidget,
    );
  });

  testWidgets('Discover replaces Shop with For You and Latest feed states', (
    tester,
  ) async {
    final forYou = DiscoverController(
      'FOR_YOU',
      pageLoader: (_, {cursor, requestId}) async =>
          const DiscoverPageDto([], null),
    );
    final latest = DiscoverController(
      'LATEST',
      pageLoader: (_, {cursor, requestId}) async =>
          DiscoverPageDto([_card()], null),
    );
    addTearDown(forYou.dispose);
    addTearDown(latest.dispose);

    await tester.pumpWidget(
      localizedTestApp(
        home: DiscoverPage(forYouController: forYou, latestController: latest),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('For You')),
      findsOneWidget,
    );
    expect(find.text('Shop'), findsNothing);
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(
      find.text('No published ceramics are available yet.'),
      findsOneWidget,
    );

    expect(latest.items.single.publicationId, 'publication-id');
    await tester.drag(find.byType(TabBarView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.index, 1);
    expect(find.text('potter'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    final creatorButton = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'potter',
      ),
    );
    final publicationSemantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Published bowl',
      ),
    );
    expect(creatorButton.tooltip, 'potter');
    expect(creatorButton.onPressed, isNotNull);
    expect(publicationSemantics.properties.button, isTrue);
    expect(find.byTooltip('Like'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
  });

  testWidgets('Discover error state retries without showing backend details', (
    tester,
  ) async {
    var attempts = 0;
    final forYou = DiscoverController(
      'FOR_YOU',
      pageLoader: (_, {cursor, requestId}) async {
        attempts++;
        if (attempts == 1) throw Exception('private database detail');
        return const DiscoverPageDto([], null);
      },
    );
    final latest = DiscoverController(
      'LATEST',
      pageLoader: (_, {cursor, requestId}) async =>
          const DiscoverPageDto([], null),
    );
    addTearDown(forYou.dispose);
    addTearDown(latest.dispose);

    await tester.pumpWidget(
      localizedTestApp(
        home: DiscoverPage(forYouController: forYou, latestController: latest),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('private database detail'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(
      find.text('No published ceramics are available yet.'),
      findsOneWidget,
    );
  });

  testWidgets('Discover renders initial and incremental loading separately', (
    tester,
  ) async {
    final firstPage = Completer<DiscoverPageDto>();
    final secondPage = Completer<DiscoverPageDto>();
    var calls = 0;
    final forYou = DiscoverController(
      'FOR_YOU',
      pageLoader: (_, {cursor, requestId}) {
        calls++;
        return calls == 1 ? firstPage.future : secondPage.future;
      },
    );
    final latest = DiscoverController(
      'LATEST',
      pageLoader: (_, {cursor, requestId}) async =>
          const DiscoverPageDto([], null),
    );
    addTearDown(forYou.dispose);
    addTearDown(latest.dispose);
    await tester.pumpWidget(
      localizedTestApp(
        home: DiscoverPage(forYouController: forYou, latestController: latest),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Published bowl'), findsNothing);

    firstPage.complete(DiscoverPageDto([_card()], 'next'));
    await tester.pump();
    await tester.pump();
    expect(forYou.items.single.publicationId, 'publication-id');
    expect(forYou.loading, isFalse);
    await tester.drag(
      find.byKey(const ValueKey('discover-feed-FOR_YOU')),
      const Offset(0, -500),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(forYou.loading, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    secondPage.complete(const DiscoverPageDto([], null));
    await tester.pumpAndSettle();
    expect(forYou.loading, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'Discover preserves image aspect ratio and exposes an error placeholder',
    (tester) async {
      final forYou = DiscoverController(
        'FOR_YOU',
        pageLoader: (_, {cursor, requestId}) async => DiscoverPageDto([
          _card(imageUri: 'https://example.invalid/publication.jpg'),
        ], null),
      );
      final latest = DiscoverController(
        'LATEST',
        pageLoader: (_, {cursor, requestId}) async =>
            const DiscoverPageDto([], null),
      );
      addTearDown(forYou.dispose);
      addTearDown(latest.dispose);
      await tester.pumpWidget(
        localizedTestApp(
          home: DiscoverPage(
            forYouController: forYou,
            latestController: latest,
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
      final context = tester.element(find.byType(Image));
      final errorWidget = image.errorBuilder!(
        context,
        Exception('offline'),
        null,
      );
      await tester.pumpWidget(MaterialApp(home: errorWidget));
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'five-second Not interested snackbar undoes through DELETE transport',
    (tester) async {
      final updates = <bool>[];
      final forYou = DiscoverController(
        'FOR_YOU',
        pageLoader: (_, {cursor, requestId}) async =>
            DiscoverPageDto([_card()], null),
        notInterestedUpdater: (publicationId, hidden) async {
          updates.add(hidden);
        },
      );
      final latest = DiscoverController(
        'LATEST',
        pageLoader: (_, {cursor, requestId}) async =>
            const DiscoverPageDto([], null),
      );
      addTearDown(forYou.dispose);
      addTearDown(latest.dispose);
      await tester.pumpWidget(
        localizedTestApp(
          home: DiscoverPage(
            forYouController: forYou,
            latestController: latest,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not interested').last);
      await tester.pumpAndSettle();

      expect(updates, [true]);
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        const Duration(seconds: 5),
      );
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(updates, [true, false]);
      expect(forYou.items.single.publicationId, 'publication-id');
    },
  );

  testWidgets('curated publication detail renders only public presentation', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: PublicationDetailPage(
          publicationId: 'publication-id',
          initialDetail: _detail(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Published bowl'), findsOneWidget);
    expect(find.text('potter'), findsOneWidget);
    expect(find.text('Clay: Stoneware'), findsOneWidget);
    expect(find.text('blue'), findsOneWidget);
    expect(find.text('Even glaze'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets('chat publication card preserves layout and unavailable state', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatPublicationCard(
                card: ChatPublicationCardDto(
                  available: true,
                  publication: _card(),
                ),
                onTap: () {},
              ),
              const ChatPublicationCard(
                card: ChatPublicationCardDto(available: false),
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Published bowl'), findsOneWidget);
    expect(find.text('Published ceramic unavailable'), findsOneWidget);
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);

    final availableSemantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Published bowl',
      ),
    );
    expect(availableSemantics.properties.label, 'Published bowl');
    expect(availableSemantics.properties.button, isTrue);
  });
}

PublicationCardDto _card({String? imageUri}) => PublicationCardDto(
  publicationId: 'publication-id',
  creator: const PublicationCreatorDto(
    userId: 'creator-id',
    username: 'potter',
    avatarInitials: 'PO',
    avatarColor: '#355070',
  ),
  title: 'Published bowl',
  primaryImage: imageUri == null
      ? null
      : PublicationImageDto(id: 7, uri: imageUri),
  clay: 'Stoneware',
  likeCount: 4,
  likedByMe: false,
  ownedByMe: false,
  publishedAt: DateTime.utc(2026, 7, 25),
);

PublicationDetailDto _detail() => PublicationDetailDto(
  publicationId: 'publication-id',
  creator: const PublicationCreatorDto(
    userId: 'creator-id',
    username: 'potter',
    avatarInitials: 'PO',
    avatarColor: '#355070',
  ),
  images: const [],
  totalImageCount: 0,
  title: 'Published bowl',
  clay: 'Stoneware',
  tags: const ['blue'],
  rating: 5,
  outcome: 'Even glaze',
  publishedAt: DateTime.utc(2026, 7, 25),
  likeCount: 4,
  likedByMe: false,
  currentAudience: 'EVERYONE',
);
