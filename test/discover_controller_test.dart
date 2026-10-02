import 'dart:async';

import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/ui/pages/discover/discover_controller.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscoverController loading', () {
    test(
      'paginates, removes duplicate cards, and refreshes from scratch',
      () async {
        final cursors = <String?>[];
        final controller = DiscoverController(
          'LATEST',
          pageLoader: (mode, {cursor, requestId}) async {
            expect(mode, 'LATEST');
            cursors.add(cursor);
            return switch (cursors.length) {
              1 => DiscoverPageDto([_card('a'), _card('b')], 'next'),
              2 => DiscoverPageDto([_card('b'), _card('c')], null),
              _ => DiscoverPageDto([_card('fresh')], null),
            };
          },
        );
        addTearDown(controller.dispose);

        expect(await controller.load(), isTrue);
        expect(await controller.load(), isTrue);
        expect(controller.items.map((item) => item.publicationId), [
          'a',
          'b',
          'c',
        ]);

        expect(await controller.load(refresh: true), isTrue);
        expect(controller.items.map((item) => item.publicationId), ['fresh']);
        expect(cursors, [null, 'next', null]);
        expect(controller.nextCursor, isNull);
      },
    );

    test('expired For You session replaces rather than mixes items', () async {
      final cursors = <String?>[];
      final controller = DiscoverController(
        'FOR_YOU',
        pageLoader: (mode, {cursor, requestId}) async {
          cursors.add(cursor);
          if (cursors.length == 1) {
            return DiscoverPageDto([_card('old-session')], 'expired-cursor');
          }
          if (cursors.length == 2) {
            throw const ApiException(
              'Expired',
              code: 'DISCOVER_SESSION_EXPIRED',
            );
          }
          return DiscoverPageDto([_card('new-session')], null);
        },
      );
      addTearDown(controller.dispose);

      await controller.load();
      expect(await controller.load(), isTrue);

      expect(cursors, [null, 'expired-cursor', null]);
      expect(controller.items.single.publicationId, 'new-session');
      expect(controller.error, isNull);
      expect(controller.loading, isFalse);
    });

    test(
      'reports an ordinary load error without exposing it as data',
      () async {
        final controller = DiscoverController(
          'LATEST',
          pageLoader: (mode, {cursor, requestId}) async => throw const ApiException(
            'Internal database detail',
            code: 'INTERNAL_ERROR',
          ),
        );
        addTearDown(controller.dispose);

        expect(await controller.load(), isFalse);
        expect(controller.items, isEmpty);
        expect(controller.error, isA<ApiException>());
        expect(controller.loading, isFalse);
      },
    );

    test('reuses the logical request ID when a failed page is retried', () async {
      final requestIds = <String?>[];
      var attempts = 0;
      final controller = DiscoverController(
        'LATEST',
        pageLoader: (mode, {cursor, requestId}) async {
          requestIds.add(requestId);
          attempts++;
          if (attempts == 1) throw const ApiException('Temporary failure');
          return const DiscoverPageDto([], null);
        },
      );
      addTearDown(controller.dispose);

      expect(await controller.load(), isFalse);
      expect(await controller.load(), isTrue);

      expect(requestIds, hasLength(2));
      expect(requestIds.first, isNotNull);
      expect(requestIds.last, requestIds.first);
    });
  });

  group('DiscoverController interactions', () {
    test('likes optimistically and reconciles the server response', () async {
      final response = Completer<PublicationCardDto>();
      final controller = DiscoverController(
        'LATEST',
        likeUpdater: (card, liked) {
          expect(card.publicationId, 'post');
          expect(liked, isTrue);
          return response.future;
        },
      );
      addTearDown(controller.dispose);
      controller.items.add(_card('post', likeCount: 2));

      final update = controller.toggleLike(0);
      expect(controller.items.single.likedByMe, isTrue);
      expect(controller.items.single.likeCount, 3);

      response.complete(_card('post', likeCount: 7, likedByMe: true));
      await update;
      expect(controller.items.single.likeCount, 7);
      expect(controller.items.single.likedByMe, isTrue);
    });

    test('rolls an optimistic like back when the request fails', () async {
      final response = Completer<PublicationCardDto>();
      final controller = DiscoverController(
        'LATEST',
        likeUpdater: (_, _) => response.future,
      );
      addTearDown(controller.dispose);
      controller.items.add(_card('post', likeCount: 2));

      final update = controller.toggleLike(0);
      expect(controller.items.single.likeCount, 3);
      response.completeError(Exception('offline'));
      await update;

      expect(controller.items.single.likeCount, 2);
      expect(controller.items.single.likedByMe, isFalse);
    });

    test(
      'Not interested removes a card and Undo reverses the request',
      () async {
        final updates = <(String, bool)>[];
        final controller = DiscoverController(
          'FOR_YOU',
          notInterestedUpdater: (publicationId, hidden) async {
            updates.add((publicationId, hidden));
          },
        );
        addTearDown(controller.dispose);
        controller.items.addAll([_card('first'), _card('second')]);

        final removed = await controller.hide(0);
        expect(removed?.publicationId, 'first');
        expect(controller.items.single.publicationId, 'second');

        await controller.undoHide(0, removed!);
        expect(controller.items.map((item) => item.publicationId), [
          'first',
          'second',
        ]);
        expect(updates, [('first', true), ('first', false)]);
      },
    );

    test('failed Not interested request restores the removed card', () async {
      final controller = DiscoverController(
        'FOR_YOU',
        notInterestedUpdater: (_, _) async => throw Exception('offline'),
      );
      addTearDown(controller.dispose);
      controller.items.addAll([_card('first'), _card('second')]);

      await expectLater(controller.hide(0), throwsException);
      expect(controller.items.map((item) => item.publicationId), [
        'first',
        'second',
      ]);
    });
  });
}

PublicationCardDto _card(
  String id, {
  int likeCount = 0,
  bool likedByMe = false,
}) => PublicationCardDto(
  publicationId: id,
  creator: const PublicationCreatorDto(
    userId: 'creator',
    username: 'potter',
    avatarInitials: 'PO',
    avatarColor: '#355070',
  ),
  title: 'Piece $id',
  likeCount: likeCount,
  likedByMe: likedByMe,
  ownedByMe: false,
  publishedAt: DateTime.utc(2026, 7, 25),
);
