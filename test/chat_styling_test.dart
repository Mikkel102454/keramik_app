import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/l10n/app_localizations.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/ui/pages/notification/conversation_page.dart';
import 'package:clay_dock/ui/pages/notification/conversation_page_controller.dart';
import 'package:clay_dock/ui/pages/profile/basic_profile_page.dart';
import 'package:clay_dock/ui/widgets/chat_attachment.dart';
import 'package:clay_dock/ui/widgets/profile_avatar.dart';
import 'package:clay_dock/ui/widgets/v2/ui_library.dart';
import 'package:clay_dock/utils/emoji_insertion.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';
import 'unified_messaging_test.dart' as messaging;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('voice pill matches a single text line at scale $scale', (
      tester,
    ) async {
      for (final state in ['play', 'pause', 'loading', 'retry']) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    key: const ValueKey('single-line-text'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: const Text('Hello', style: TextStyle(height: 1.25)),
                  ),
                  VoiceMessagePill(
                    mine: false,
                    durationMs: 3000,
                    playing: state == 'pause',
                    loading: state == 'loading',
                    error: state == 'retry',
                    onPressed: state == 'loading' ? null : () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.getSize(find.byType(VoiceMessagePill)).height,
          closeTo(
            tester
                .getSize(find.byKey(const ValueKey('single-line-text')))
                .height,
            0.01,
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  }
  late messaging.MessagingAdapter adapter;
  setUp(() {
    adapter = messaging.MessagingAdapter();
    ApiClient.dio = Dio(
      BaseOptions(
        baseUrl: 'https://isolated.test',
        validateStatus: (_) => true,
      ),
    )..httpClientAdapter = adapter;
  });
  tearDown(() => ApiClient.dio.close(force: true));

  Future<void> openChat(WidgetTester tester, {String type = 'DIRECT'}) async {
    adapter.stored = messaging.conversationJson(status: 'ACTIVE', type: type);
    await tester.pumpWidget(
      localizedTestApp(
        home: ConversationPage(
          initialConversation: DirectConversationDto.fromJson(adapter.stored!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final chatType in ['DIRECT', 'GROUP']) {
    for (final messageType in [
      'TEXT',
      'VOICE',
      'IMAGE',
      'CERAMIC',
      'PUBLICATION',
    ]) {
      messaging.messagingWidgetTest(
        '$chatType scrolls to acknowledged $messageType below variable-height history',
        (tester) async {
          adapter.stored = messaging.conversationJson(
            status: 'ACTIVE',
            type: chatType,
          );
          for (var sequence = 1; sequence <= 45; sequence++) {
            adapter.messages.add(
              adapter.message(
                List.filled(
                  sequence % 7 + 1,
                  'Earlier message $sequence',
                ).join('\n'),
                sequence,
              ),
            );
          }
          final conversation = DirectConversationDto.fromJson(adapter.stored!);
          final controller = ConversationPageController(conversation);
          await tester.pumpWidget(
            localizedTestApp(
              home: ConversationPage(
                initialConversation: conversation,
                controller: controller,
                loadAttachment: (_) => Future<File>.error(
                  StateError('Isolated unavailable media'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final history = find.byWidgetPredicate(
            (widget) => widget is ListView && widget.controller != null,
          );
          final scroll = tester.widget<ListView>(history).controller!;
          expect(scroll.position.extentBefore, lessThanOrEqualTo(1));
          scroll.jumpTo(1000);
          final sent = ChatMessageDto.fromJson({
            ...adapter.message('Newest $messageType', 46),
            'id': 'scroll-sent-$chatType-$messageType',
            'type': messageType,
            if (messageType == 'IMAGE' || messageType == 'VOICE')
              'attachment': {
                'type': messageType,
                'size': 128,
                if (messageType == 'IMAGE') ...{'width': 100, 'height': 300},
                if (messageType == 'VOICE') 'durationMs': 5000,
              },
          });
          controller.recordSentMessage(sent);
          await tester.pumpAndSettle();
          expect(scroll.position.extentBefore, lessThanOrEqualTo(1));
          // Reconciliation is allowed while reading older messages without forcing a scroll.
          scroll.jumpTo(1000);
          await tester.pump();
          final visibleRows = find.byWidgetPredicate(
            (widget) =>
                widget is Column && widget.key.toString().contains('chat-row-'),
          );
          final anchor = visibleRows.evaluate().firstWhere((element) {
            final y = tester.getTopLeft(find.byWidget(element.widget)).dy;
            return y > 100 && y < 300;
          }).widget;
          final anchorKey = anchor.key!;
          final anchorY = tester.getTopLeft(find.byKey(anchorKey)).dy;
          adapter.messages.add(adapter.message('Incoming during reading', 47));
          final refresh = controller.load();
          await tester.pumpAndSettle();
          await refresh;
          expect(
            tester.getTopLeft(find.byKey(anchorKey)).dy,
            closeTo(anchorY, 1),
          );
          expect(controller.sentRevision, 1);
        },
      );
    }
  }

  messaging.messagingWidgetTest(
    'timed-out optimistic text stays at bottom with Unconfirmed; retry replaces it',
    (tester) async {
      adapter.stored = messaging.conversationJson(status: 'ACTIVE');
      for (var sequence = 1; sequence <= 40; sequence++) {
        adapter.messages.add(
          adapter.message('Earlier message $sequence\nSecond line', sequence),
        );
      }
      await openChat(tester);
      final history = find.byWidgetPredicate(
        (widget) => widget is ListView && widget.controller != null,
      );
      final scroll = tester.widget<ListView>(history).controller!;
      expect(scroll.position.extentBefore, lessThanOrEqualTo(1));
      scroll.jumpTo(1000);
      await tester.enterText(find.byType(TextField), 'Newest sent text');
      await tester.pump();
      adapter.loseNextResponse = true;
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(scroll.position.extentBefore, lessThanOrEqualTo(1));
      // The fixture commits before losing the response: delivery is unknown.
      expect(find.text('Unconfirmed'), findsOneWidget);
      expect(find.text('Not sent'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(scroll.position.extentBefore, lessThanOrEqualTo(1));
      expect(find.text('Newest sent text'), findsOneWidget);
      expect(find.text('Unconfirmed'), findsNothing);
      expect(find.text('Not sent'), findsNothing);
      expect(adapter.sendIds.toSet(), hasLength(1));
    },
  );

  for (final area in ['avatar', 'name', 'gap', 'trailing space']) {
    messaging.messagingWidgetTest('direct title $area opens a fresh profile', (
      tester,
    ) async {
      await openChat(tester);
      final target = find.byKey(const ValueKey('direct-chat-profile'));
      final rect = tester.getRect(target);
      final avatar = tester.getRect(
        find.descendant(of: target, matching: find.byType(ProfileAvatar)),
      );
      final name = tester.getRect(
        find.descendant(of: target, matching: find.text('potter')),
      );
      final position = switch (area) {
        'avatar' => avatar.center,
        'name' => name.center,
        'gap' => Offset(avatar.right + 5, avatar.center.dy),
        _ => Offset(rect.right - 5, rect.center.dy),
      };
      final ink = tester.widget<InkWell>(target);
      expect(ink.splashFactory, NoSplash.splashFactory);
      expect(
        ink.overlayColor!.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
      expect(
        tester.getSemantics(target).getSemanticsData().flagsCollection.isButton,
        isTrue,
      );
      await tester.tapAt(position);
      await tester.pumpAndSettle();
      expect(find.byType(BasicProfilePage), findsOneWidget);
      expect(
        adapter.requests.where(
          (r) => r.path == '/api/users/${messaging.targetId}',
        ),
        hasLength(1),
      );
    });
  }

  for (final type in ['DIRECT', 'GROUP']) {
    for (final messageType in [
      'TEXT',
      'IMAGE',
      'VOICE',
      'CERAMIC',
      'PUBLICATION',
    ]) {
      messaging.messagingWidgetTest(
        '$type $messageType has received-only sender avatars',
        (tester) async {
          adapter.stored = messaging.conversationJson(
            status: 'ACTIVE',
            type: type,
          );
          adapter.messages.addAll([
            {
              ...adapter.message('received', 1),
              'mine': false,
              'type': messageType,
              'senderUsername': 'sender',
              'senderAvatarInitials': 'SE',
              'senderAvatarColor': '#123456',
              if (messageType == 'IMAGE' || messageType == 'VOICE')
                'attachment': {
                  'type': messageType,
                  'size': 100,
                  'width': 100,
                  'height': 100,
                  'durationMs': 3000,
                },
            },
            {...adapter.message('mine', 2), 'type': messageType},
            {...adapter.message('system', 3), 'mine': false, 'type': 'SYSTEM'},
          ]);
          await tester.pumpWidget(
            localizedTestApp(
              home: ConversationPage(
                initialConversation: DirectConversationDto.fromJson(
                  adapter.stored!,
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          final avatar = find.byKey(const ValueKey('chat-avatar-message-1'));
          expect(avatar, findsOneWidget);
          final avatarInk = tester.widget<InkWell>(avatar);
          expect(avatarInk.splashFactory, NoSplash.splashFactory);
          expect(
            avatarInk.overlayColor!.resolve({WidgetState.pressed}),
            Colors.transparent,
          );
          expect(
            find.byKey(const ValueKey('chat-avatar-message-2')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('chat-avatar-message-3')),
            findsNothing,
          );
          final profile = tester.widget<ProfileAvatar>(
            find.descendant(of: avatar, matching: find.byType(ProfileAvatar)),
          );
          expect(profile.initials, type == 'GROUP' ? 'SE' : 'PO');
          expect(profile.colorHex, type == 'GROUP' ? '#123456' : '#355070');
          if (messageType == 'TEXT') {
            final bubble = find.ancestor(
              of: find.text('received'),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration! as BoxDecoration).borderRadius ==
                        BorderRadius.circular(24),
              ),
            );
            expect(bubble, findsOneWidget);
            final avatarCircle = find.descendant(
              of: avatar,
              matching: find.byType(ProfileAvatar),
            );
            expect(
              tester.getRect(avatarCircle).bottom,
              tester.getRect(bubble).bottom,
            );
            expect(
              tester.getRect(find.text('received')).left,
              lessThan(tester.getRect(find.text('mine')).left),
            );
          }
          await tester.tap(avatar);
          await tester.pumpAndSettle();
          expect(find.byType(BasicProfilePage), findsOneWidget);
        },
      );
    }
  }

  messaging.messagingWidgetTest(
    'failed send keeps draft and retry clears it and restores media',
    (tester) async {
      await openChat(tester);
      await tester.enterText(find.byType(TextField), 'Keep this draft');
      await tester.pump();
      expect(find.byIcon(Icons.mic_none), findsNothing);
      expect(find.byIcon(Icons.photo_outlined), findsNothing);
      adapter.loseNextResponse = true;
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Keep this draft',
      );
      // Let the existing error snackbar finish before tapping beneath it.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
      expect(adapter.sendIds.toSet(), hasLength(1));
    },
  );

  testWidgets(
    'composer reacts to text emoji clearing and sending without losing focus',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var sends = 0;
      Widget composer({bool sending = false}) => localizedTestApp(
        home: Scaffold(
          body: MessageComposer(
            controller: controller,
            sending: sending,
            onSend: () => sends++,
            onEmoji: () => controller.value = insertChatEmoji(
              controller.value,
              '\u{1f600}',
            ),
            onVoice: () {},
            onImage: () {},
            onCeramic: () {},
          ),
        ),
      );
      await tester.pumpWidget(composer());
      expect(find.byIcon(Icons.send), findsNothing);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '  \n ');
      await tester.pump();
      expect(find.byIcon(Icons.mic_none), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byIcon(Icons.sentiment_satisfied_alt_outlined));
      await tester.pump();
      expect(controller.text, contains('\u{1f600}'));
      expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.send));
      expect(sends, 1);
      await tester.pumpWidget(composer(sending: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Edit while sending');
      expect(controller.text, contains('\u{1f600}'));
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.pumpWidget(composer());
      controller.clear();
      await tester.pump();
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
      await tester.enterText(find.byType(TextField), 'a' * 1999 + '\u{1f600}');
      expect(controller.text.runes.length, 2000);
      await tester.enterText(
        find.byType(TextField),
        'a' * 1999 + '\u{1f469}\u{1f3fd}',
      );
      expect(controller.text.runes.length, 2000);
    },
  );

  testWidgets(
    'voice loading and failure preserve duration with a retry action',
    (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: VoiceMessagePill(
              mine: false,
              durationMs: 3000,
              loading: true,
              onPressed: null,
            ),
          ),
        ),
      );
      expect(find.text('0:03'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: VoiceMessagePill(
              mine: false,
              durationMs: 3000,
              error: true,
              onPressed: () => retries++,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.refresh));
      expect(retries, 1);
      expect(find.text('0:03'), findsOneWidget);
    },
  );

  testWidgets(
    'photo retains proportions through loading failure retry and zoom viewer',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('chat-style-'),
      ))!;
      final file = File('${directory.path}/image.png');
      await tester.runAsync(
        () => file.writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aP1sAAAAASUVORK5CYII=',
          ),
        ),
      );
      final download = Completer<File>();
      var attempts = 0;
      final message = ChatMessageDto.fromJson({
        'id': 'photo-layout',
        'senderUserId': messaging.targetId,
        'body': 'Image',
        'createdAt': '2026-10-03T10:00:00Z',
        'sequence': 1,
        'mine': false,
        'type': 'IMAGE',
        'attachment': {
          'type': 'IMAGE',
          'size': 100,
          'width': 100,
          'height': 200,
        },
      });
      try {
        await tester.pumpWidget(
          localizedTestApp(
            home: Scaffold(
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: ChatAttachment(
                    conversation: 'photo-layout-test',
                    message: message,
                    loadFile: () =>
                        ++attempts == 1 ? download.future : Future.value(file),
                  ),
                ),
              ),
            ),
          ),
        );
        final preview = find.byKey(const ValueKey('chat-photo-photo-layout'));
        expect(tester.getSize(preview), const Size(170, 340));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        download.completeError(const FileSystemException('Unavailable'));
        await tester.pumpAndSettle();
        expect(tester.getSize(preview), const Size(170, 340));
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(attempts, 2);
        expect(tester.getSize(preview), const Size(170, 340));
        expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
        expect(find.byType(ClipRRect), findsOneWidget);
        await tester.tap(find.byType(Image));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.runAsync(() => directory.delete(recursive: true));
      }
    },
  );

  for (final locale in ['en', 'da']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        '$locale $brightness compact composer and voice handle large text and keyboard',
        (tester) async {
          tester.view.physicalSize = const Size(320, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = TextEditingController();
          addTearDown(controller.dispose);
          var playing = false;
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(brightness: brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 240),
                ),
                child: child!,
              ),
              home: StatefulBuilder(
                builder: (context, setState) => Scaffold(
                  body: Column(
                    children: [
                      VoiceMessagePill(
                        mine: true,
                        durationMs: 65000,
                        playing: playing,
                        onPressed: () => setState(() => playing = !playing),
                      ),
                      const Spacer(),
                      MessageComposer(
                        controller: controller,
                        sending: false,
                        onSend: () {},
                        onEmoji: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('1:05'), findsOneWidget);
          await tester.tap(find.byIcon(Icons.play_arrow));
          await tester.pump();
          expect(find.byIcon(Icons.pause), findsOneWidget);
          await tester.tap(find.byIcon(Icons.pause));
          await tester.pump();
          expect(find.byIcon(Icons.play_arrow), findsOneWidget);
          await tester.enterText(
            find.byType(TextField),
            'First line\nSecond line',
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
