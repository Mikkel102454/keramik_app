import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/ui/pages/notification/conversation_page.dart';
import 'package:clay_dock/ui/pages/notification/conversation_page_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';
import 'unified_messaging_test.dart' as messaging;

class PagedHistoryAdapter extends messaging.MessagingAdapter {
  PagedHistoryAdapter({int count = 1000}) {
    stored = messaging.conversationJson(status: 'ACTIVE');
    history = [
      for (var i = 1; i <= count; i++)
        {
          ...message(
            'Message $i\n${List.filled(i % 4 + 1, 'Second line').join('\n')}',
            i,
          ),
          if (i % 10 == 9) ...{
            'type': 'IMAGE',
            'attachment': {
              'type': 'IMAGE',
              'size': 8,
              'width': 100,
              'height': 300,
            },
          },
        },
    ];
  }
  late final List<Map<String, dynamic>> history;
  final List<RequestOptions> historyRequests = [];
  Completer<void>? latestGate;
  Completer<void>? olderGate;
  bool failOlder = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method != 'GET' || !options.path.endsWith('/messages')) {
      return super.fetch(options, requestStream, cancelFuture);
    }
    historyRequests.add(options);
    final cursor = options.queryParameters['before'] as String?;
    final limit = options.queryParameters['limit'] as int;
    if (cursor == null) {
      await latestGate?.future;
    } else {
      await olderGate?.future;
      if (failOlder) {
        failOlder = false;
        return response(null, success: false);
      }
    }
    final before = cursor == null
        ? history.length + 1
        : int.parse(cursor.substring(7));
    final eligible = history
        .where((row) => (row['sequence'] as int) < before)
        .toList();
    final start = (eligible.length - limit).clamp(0, eligible.length);
    final items = eligible.sublist(start);
    return response({
      'items': items,
      'nextCursor': start == 0 ? null : 'before-${items.first['sequence']}',
    });
  }
}

Finder historyList() => find.byWidgetPredicate(
  (widget) => widget is ListView && widget.controller != null,
);

void main() {
  late PagedHistoryAdapter adapter;
  setUp(() {
    adapter = PagedHistoryAdapter();
    ApiClient.dio = Dio(
      BaseOptions(
        baseUrl: 'https://isolated.test',
        validateStatus: (_) => true,
      ),
    )..httpClientAdapter = adapter;
  });
  tearDown(() => ApiClient.dio.close(force: true));

  Future<ConversationPageController> openChat(
    WidgetTester tester, {
    String type = 'DIRECT',
    List<String>? downloads,
  }) async {
    adapter.stored = messaging.conversationJson(status: 'ACTIVE', type: type);
    final conversation = DirectConversationDto.fromJson(adapter.stored!);
    final controller = ConversationPageController(conversation);
    await tester.pumpWidget(
      localizedTestApp(
        home: ConversationPage(
          initialConversation: conversation,
          controller: controller,
          loadAttachment: (message) {
            downloads?.add(message.id);
            return Future<File>.error(StateError('Isolated unavailable media'));
          },
        ),
      ),
    );
    return controller;
  }

  for (final type in ['DIRECT', 'GROUP']) {
    messaging.messagingWidgetTest(
      '$type first history frame starts at bottom, fetches one page and builds visible rows',
      (tester) async {
        adapter.latestGate = Completer<void>();
        final downloads = <String>[];
        final controller = await openChat(
          tester,
          type: type,
          downloads: downloads,
        );
        await tester.pump();
        expect(historyList(), findsNothing);
        adapter.latestGate!.complete();
        // Inspect the very first frame containing history, before settling any
        // post-frame jump or animation. A forward list fails these assertions.
        for (
          var attempt = 0;
          attempt < 20 && historyList().evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 1));
        }
        expect(historyList(), findsOneWidget);
        final list = tester.widget<ListView>(historyList());
        final scroll = list.controller!;
        expect(list.reverse, isTrue);
        expect(scroll.offset, 0);
        final newest = find.byKey(const ValueKey('chat-row-message-1000'));
        expect(newest, findsOneWidget);
        final newestRect = tester.getRect(newest);
        final viewportRect = tester.getRect(historyList());
        expect(newestRect.top, greaterThanOrEqualTo(viewportRect.top));
        expect(newestRect.bottom, lessThanOrEqualTo(viewportRect.bottom));
        expect(
          find.byKey(const ValueKey('chat-row-message-951')),
          findsNothing,
        );
        final built = find
            .byWidgetPredicate(
              (widget) =>
                  widget is Column &&
                  widget.key.toString().contains('chat-row-'),
            )
            .evaluate()
            .length;
        expect(built, lessThan(50));
        expect(controller.messages, hasLength(50));
        expect(adapter.historyRequests, hasLength(1));
        expect(adapter.historyRequests.single.queryParameters, {'limit': 50});
        expect(downloads.length, lessThan(5));
        await tester.pumpAndSettle();
        expect(scroll.offset, 0);
        expect(adapter.historyRequests, hasLength(1));
      },
    );

    messaging.messagingWidgetTest(
      '$type scroll loads one older page without moving the reading anchor; refresh retains it',
      (tester) async {
        final controller = await openChat(tester, type: type);
        await tester.pumpAndSettle();
        adapter.olderGate = Completer<void>();
        final scroll = tester.widget<ListView>(historyList()).controller!;
        scroll.jumpTo(scroll.position.maxScrollExtent - 50);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 2),
        );
        expect(controller.isLoadingOlder, isTrue);
        expect(adapter.historyRequests, hasLength(2));
        expect(adapter.historyRequests.last.queryParameters, {
          'limit': 50,
          'before': 'before-951',
        });
        final offset = scroll.offset;
        final anchor = find.byKey(const ValueKey('chat-row-message-952'));
        final anchorY = tester.getTopLeft(anchor).dy;
        await controller
            .loadOlder(); // A duplicate trigger is ignored in flight.
        expect(adapter.historyRequests, hasLength(2));
        adapter.olderGate!.complete();
        await tester.pumpAndSettle();
        expect(controller.messages, hasLength(100));
        expect(controller.beforeCursor, 'before-901');
        expect(scroll.offset, closeTo(offset, 1));
        expect(tester.getTopLeft(anchor).dy, closeTo(anchorY, 1));
        expect(adapter.historyRequests, hasLength(2));
        final refresh = controller.load();
        await tester.pumpAndSettle();
        await refresh;
        expect(controller.messages, hasLength(100));
        expect(controller.messages.first.sequence, 901);
        expect(controller.beforeCursor, 'before-901');
        expect(tester.getTopLeft(anchor).dy, closeTo(anchorY, 1));
        expect(adapter.historyRequests.last.queryParameters, {'limit': 50});
      },
    );
  }

  messaging.messagingWidgetTest(
    'older-page failure keeps cursor and history, and explicit retry stops at history end',
    (tester) async {
      adapter = PagedHistoryAdapter(count: 75);
      ApiClient.dio.httpClientAdapter = adapter;
      final controller = await openChat(tester);
      await tester.pumpAndSettle();
      adapter.failOlder = true;
      final scroll = tester.widget<ListView>(historyList()).controller!;
      scroll.jumpTo(scroll.position.maxScrollExtent - 50);
      await tester.pumpAndSettle();
      expect(controller.messages, hasLength(50));
      expect(controller.beforeCursor, 'before-26');
      expect(controller.error, isNotNull);
      expect(adapter.historyRequests, hasLength(2));
      scroll.jumpTo(scroll.position.maxScrollExtent - 25);
      await tester.pumpAndSettle();
      expect(adapter.historyRequests, hasLength(2));
      final retry = controller.loadOlder();
      await tester.pumpAndSettle();
      await retry;
      expect(controller.error, isNull);
      expect(controller.messages, hasLength(75));
      expect(controller.messages.map((row) => row.id).toSet(), hasLength(75));
      expect(controller.beforeCursor, isNull);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(adapter.historyRequests, hasLength(3));
    },
  );
}
