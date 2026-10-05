import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/objects/user_profile_dto.dart';
import 'package:clay_dock/repositories/chat_repository.dart';
import 'package:clay_dock/ui/pages/notification/conversation_page.dart';
import 'package:clay_dock/ui/pages/notification/conversation_page_controller.dart';
import 'package:clay_dock/ui/pages/profile/basic_profile_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

const targetId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
void messagingWidgetTest(String name, WidgetTesterCallback callback) {
  testWidgets(name, (tester) async {
    try {
      await callback(tester);
    } finally {
      // Settle disposal's shared playback pause inside this test's fake clock.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
}

const conversationId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const profileJson = <String, dynamic>{
  'userId': targetId,
  'username': 'potter',
  'avatarInitials': 'PO',
  'avatarColor': '#355070',
  'relationshipState': 'NONE',
  'actions': ['MESSAGE_REQUEST'],
};

Map<String, dynamic> conversationJson({
  String status = 'PENDING',
  bool incoming = false,
  int remaining = 2,
  String type = 'DIRECT',
}) => {
  'id': conversationId,
  'status': status,
  'type': type,
  'title': type == 'GROUP' ? 'Studio group' : 'potter',
  'otherUser': type == 'GROUP' ? null : profileJson,
  'avatarInitials': 'PO',
  'avatarColor': '#355070',
  'unreadCount': 0,
  'archived': false,
  'incomingRequest': incoming,
  'readOnly': status != 'ACTIVE' && (incoming || remaining == 0),
  'requestMessagesRemaining': status == 'PENDING' && !incoming ? remaining : 0,
};

void main() {
  late MessagingAdapter adapter;
  setUp(() {
    adapter = MessagingAdapter();
    ApiClient.dio = Dio(
      BaseOptions(
        baseUrl: 'https://isolated.test',
        validateStatus: (_) => true,
      ),
    )..httpClientAdapter = adapter;
  });
  tearDown(() => ApiClient.dio.close(force: true));

  messagingWidgetTest(
    'one Message button opens a draft and cancelling writes nothing',
    (tester) async {
      final profile = UserProfileDto.fromJson({
        ...profileJson,
        'actions': ['MESSAGE', 'MESSAGE_REQUEST'],
      });
      await tester.pumpWidget(
        localizedTestApp(
          home: BasicProfilePage(
            initialProfile: profile,
            loadFinishedCeramics: (_) async => [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Message'), findsOneWidget);
      expect(find.text('Send message request'), findsNothing);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Message'));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationPage), findsOneWidget);
      expect(find.text('3 messages remaining'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(adapter.posts, isEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(adapter.posts, isEmpty);
      expect(adapter.stored, isNull);
    },
  );

  test(
    'friends create an active chat; existing non-friend chats open without creation',
    () async {
      adapter.friends = true;
      final friendChat = await ChatRepository.openDirect(targetId);
      expect(friendChat.status, 'ACTIVE');
      expect(adapter.posts.single.path, '/api/chat/direct');
      adapter.friends = false;
      adapter.posts.clear();
      final existing = await ChatRepository.openDirect(targetId);
      expect(existing.id, friendChat.id);
      expect(adapter.posts, isEmpty);
      adapter.stored = conversationJson();
      expect((await ChatRepository.openDirect(targetId)).status, 'PENDING');
      adapter.stored = conversationJson(status: 'DECLINED', remaining: 0);
      expect((await ChatRepository.openDirect(targetId)).readOnly, isTrue);
    },
  );

  test(
    'first successful send persists draft then two more texts exhaust allowance',
    () async {
      final controller = ConversationPageController(
        DirectConversationDto.draft(UserProfileDto.fromJson(profileJson)),
      );
      addTearDown(controller.dispose);
      expect(await controller.sendCeramic(1), isFalse);
      expect(adapter.posts, isEmpty);
      expect(await controller.send('first'), isTrue);
      expect(controller.conversation.isDraft, isFalse);
      expect(controller.messages.single.body, 'first');
      expect(controller.conversation.requestMessagesRemaining, 2);
      expect(await controller.send('second'), isTrue);
      expect(controller.conversation.requestMessagesRemaining, 1);
      expect(await controller.send('third'), isTrue);
      expect(controller.conversation.readOnly, isTrue);
      expect(controller.conversation.requestMessagesRemaining, 0);
      expect(await controller.send('fourth'), isFalse);
      expect(controller.messages, hasLength(3));
      expect(
        adapter.posts.where((r) => r.path == '/api/chat/direct/messages'),
        hasLength(1),
      );
    },
  );

  test(
    'lost first-send response reuses UUID and loads one persisted message',
    () async {
      final controller = ConversationPageController(
        DirectConversationDto.draft(UserProfileDto.fromJson(profileJson)),
      );
      addTearDown(controller.dispose);
      adapter.loseNextResponse = true;
      expect(await controller.send('first'), isFalse);
      expect(controller.conversation.isDraft, isTrue);
      expect(await controller.send('first'), isTrue);
      expect(adapter.sendIds.toSet(), hasLength(1));
      expect(controller.messages, hasLength(1));
      expect(controller.conversation.requestMessagesRemaining, 2);
    },
  );

  test(
    'lost third-send response can be retried after refreshing the exhausted chat',
    () async {
      adapter.stored = conversationJson(remaining: 1);
      adapter.messages.addAll([
        adapter.message('first', 1),
        adapter.message('second', 2),
      ]);
      final controller = ConversationPageController(
        DirectConversationDto.fromJson(adapter.stored!),
      );
      addTearDown(controller.dispose);
      await controller.load();
      adapter.loseNextResponse = true;
      expect(await controller.send('third'), isFalse);
      await controller.load();
      expect(controller.conversation.readOnly, isTrue);
      expect(controller.hasPendingTextSend, isTrue);
      final exhausted = controller.conversation;
      for (final status in ['DECLINED', 'BLOCKED']) {
        controller.conversation = DirectConversationDto.fromJson(
          conversationJson(status: status, remaining: 0),
        );
        expect(controller.canRetryPendingText, isFalse);
        expect(await controller.send('third'), isFalse);
      }
      controller.conversation = exhausted;
      expect(await controller.send('third'), isTrue);
      expect(adapter.sendIds.toSet(), hasLength(1));
      expect(controller.messages, hasLength(3));
      expect(controller.hasPendingTextSend, isFalse);
    },
  );

  messagingWidgetTest(
    'pending sender controls are text-only and third send shows waiting',
    (tester) async {
      adapter.stored = conversationJson();
      adapter.messages.add(adapter.message('first', 1));
      await tester.pumpWidget(
        localizedTestApp(
          home: ConversationPage(
            initialConversation: DirectConversationDto.fromJson(
              adapter.stored!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final icon in [
        Icons.mic_none,
        Icons.photo_outlined,
        Icons.handyman_outlined,
      ]) {
        expect(
          tester
              .widget<IconButton>(find.widgetWithIcon(IconButton, icon))
              .onPressed,
          isNull,
        );
      }
      for (final body in ['second', 'third']) {
        await tester.enterText(find.byType(TextField), body);
        // Typing now replaces media actions with Send on the next frame.
        await tester.pump();
        await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
        await tester.pumpAndSettle();
      }
      expect(find.byType(TextField), findsNothing);
      expect(
        find.text('Waiting for the recipient to accept this request.'),
        findsOneWidget,
      );
      expect(adapter.messages, hasLength(3));
    },
  );

  messagingWidgetTest(
    'recipient must accept before replying and active controls become available',
    (tester) async {
      adapter.stored = conversationJson(incoming: true, remaining: 0);
      await tester.pumpWidget(
        localizedTestApp(
          home: ConversationPage(
            initialConversation: DirectConversationDto.fromJson(
              adapter.stored!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(
        find.text('Accept this message request to reply.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.photo_outlined),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.handyman_outlined),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  messagingWidgetTest(
    'failed request decisions show safe feedback and recover for acceptance',
    (tester) async {
      adapter.stored = conversationJson(incoming: true, remaining: 0);
      await tester.pumpWidget(
        localizedTestApp(
          home: ConversationPage(
            initialConversation: DirectConversationDto.fromJson(
              adapter.stored!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final decision in ['Decline', 'Accept']) {
        adapter.failNextRequestDecision = true;
        await tester.tap(find.text(decision));
        await tester.pumpAndSettle();
        expect(
          find.text('That action could not be completed. Please try again.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('private request transport detail'),
          findsNothing,
        );
        expect(find.textContaining('DioException'), findsNothing);
        expect(adapter.stored!['status'], 'PENDING');
        expect(find.byType(TextField), findsNothing);
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Accept'))
              .onPressed,
          isNotNull,
        );
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Decline'))
              .onPressed,
          isNotNull,
        );
        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .hideCurrentSnackBar();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
      await tester.pumpAndSettle();
      expect(adapter.stored!['status'], 'ACTIVE');
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Accept this message request to reply.'), findsNothing);
      expect(
        adapter.posts.where((request) => request.path.endsWith('/accept')),
        hasLength(2),
      );
      expect(
        adapter.posts.where((request) => request.path.endsWith('/decline')),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  messagingWidgetTest(
    'direct username loads a fresh UUID profile and refreshes chat on return',
    (tester) async {
      adapter.stored = conversationJson(status: 'ACTIVE');
      adapter.profileName = 'renamed-potter';
      await tester.pumpWidget(
        localizedTestApp(
          home: ConversationPage(
            initialConversation: DirectConversationDto.fromJson(
              adapter.stored!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('direct-chat-profile')));
      await tester.pumpAndSettle();
      expect(find.byType(BasicProfilePage), findsOneWidget);
      expect(find.text('renamed-potter'), findsOneWidget);
      expect(
        adapter.requests.where((r) => r.path == '/api/users/$targetId'),
        hasLength(1),
      );
      final reads = adapter.requests
          .where(
            (r) =>
                r.path == '/api/chat/conversations/$conversationId' &&
                r.method == 'GET',
          )
          .length;
      adapter.stored = conversationJson(status: 'BLOCKED', remaining: 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        adapter.requests
            .where(
              (r) =>
                  r.path == '/api/chat/conversations/$conversationId' &&
                  r.method == 'GET',
            )
            .length,
        reads + 1,
      );
      expect(find.byType(TextField), findsNothing);
    },
  );

  messagingWidgetTest(
    'unavailable profiles show a localized message and keep chat open',
    (tester) async {
      adapter.stored = conversationJson(status: 'ACTIVE');
      adapter.profileUnavailable = true;
      await tester.pumpWidget(
        localizedTestApp(
          home: ConversationPage(
            initialConversation: DirectConversationDto.fromJson(
              adapter.stored!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('direct-chat-profile')));
      await tester.pumpAndSettle();
      expect(find.text('This profile is unavailable.'), findsOneWidget);
      expect(find.byType(BasicProfilePage), findsNothing);
    },
  );

  for (final type in ['TEXT', 'IMAGE', 'VOICE', 'CERAMIC', 'PUBLICATION']) {
    messagingWidgetTest('$type group sender opens a fresh profile by UUID', (
      tester,
    ) async {
      adapter.stored = conversationJson(status: 'ACTIVE', type: 'GROUP');
      adapter.messages.add({
        ...adapter.message('group message', 1),
        'id': 'message-$type',
        'mine': false,
        'senderUsername': 'old-name',
        'type': type,
        if (type == 'IMAGE' || type == 'VOICE')
          'attachment': {
            'type': type,
            'size': 100,
            'width': 100,
            'height': 100,
            'durationMs': 1000,
          },
      });
      await tester.pumpWidget(
        localizedTestApp(
          home: ConversationPage(
            initialConversation: DirectConversationDto.fromJson(
              adapter.stored!,
            ),
          ),
        ),
      );
      if (type == 'IMAGE' || type == 'VOICE') {
        // Profile navigation must work while the attachment is still loading.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      } else {
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(ValueKey('chat-sender-message-$type')));
      await tester.pumpAndSettle();
      expect(find.byType(BasicProfilePage), findsOneWidget);
      expect(
        adapter.requests.where((r) => r.path == '/api/users/$targetId'),
        hasLength(1),
      );
    });
  }

  for (final locale in ['en', 'da']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      messagingWidgetTest(
        '$locale $brightness request layout handles enlarged text and keyboard',
        (tester) async {
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: _delegates,
              supportedLocales: _locales,
              theme: ThemeData(brightness: brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 240),
                ),
                child: child!,
              ),
              home: ConversationPage(
                initialConversation: DirectConversationDto.draft(
                  UserProfileDto.fromJson(profileJson),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'A keyboard draft');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(TextField), findsOneWidget);
          expect(adapter.posts, isEmpty);
        },
      );
    }
  }
}

// Reuse the app's generated locale configuration in the layout variants.
final _delegates = (localizedTestApp(home: const SizedBox()) as MaterialApp)
    .localizationsDelegates;
final _locales =
    (localizedTestApp(home: const SizedBox()) as MaterialApp).supportedLocales;

class MessagingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<RequestOptions> posts = [];
  final List<String> sendIds = [];
  final List<Map<String, dynamic>> messages = [];
  final Map<String, Map<String, dynamic>> sent = {};
  Map<String, dynamic>? stored;
  bool friends = false;
  bool loseNextResponse = false;
  bool profileUnavailable = false;
  bool failNextRequestDecision = false;
  String profileName = 'potter';

  Map<String, dynamic> message(String body, int sequence) => {
    'id': 'message-$sequence',
    'senderUserId': targetId,
    'body': body,
    'createdAt': '2026-10-03T10:00:00Z',
    'sequence': sequence,
    'mine': true,
    'type': 'TEXT',
  };

  ResponseBody response(dynamic data, {bool success = true}) =>
      ResponseBody.fromString(
        jsonEncode({
          'success': success,
          'data': data,
          if (!success) 'error': {'message': 'Unavailable'},
        }),
        success ? 200 : 404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.method == 'POST') posts.add(options);
    final path = options.path;
    if (path == '/api/chat/media') return response({'available': true});
    if (path == '/api/users/$targetId/publications') return response([]);
    if (path == '/api/users/$targetId') {
      return response({
        ...profileJson,
        'username': profileName,
      }, success: !profileUnavailable);
    }
    if (path == '/api/chat/direct/with/$targetId') {
      return response({
        'otherUser': {
          ...profileJson,
          if (friends) 'relationshipState': 'FRIENDS',
        },
        'conversation': stored,
      });
    }
    if (path == '/api/chat/direct') {
      stored = conversationJson(status: 'ACTIVE');
      return response(stored);
    }
    if (failNextRequestDecision &&
        (path.endsWith('/accept') || path.endsWith('/decline'))) {
      failNextRequestDecision = false;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'private request transport detail',
      );
    }
    if (path.endsWith('/accept')) {
      stored = conversationJson(status: 'ACTIVE');
      return response(stored);
    }
    if (path == '/api/chat/conversations/$conversationId') {
      return response(stored);
    }
    if (path.endsWith('/read')) return response(null);
    if (path.endsWith('/messages') && options.method == 'GET') {
      return response({'items': messages, 'nextCursor': null});
    }
    if (path.endsWith('/messages') && options.method == 'POST') {
      final body = options.data as Map<String, dynamic>;
      final clientId = body['clientMessageId'] as String;
      sendIds.add(clientId);
      final persisted = sent.putIfAbsent(clientId, () {
        final item = message(body['body'] as String, messages.length + 1);
        messages.add(item);
        return item;
      });
      stored = conversationJson(remaining: (3 - messages.length).clamp(0, 3));
      if (loseNextResponse) {
        loseNextResponse = false;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      }
      return response(path == '/api/chat/direct/messages' ? stored : persisted);
    }
    throw StateError('Unexpected isolated request: ${options.method} $path');
  }

  @override
  void close({bool force = false}) {}
}
