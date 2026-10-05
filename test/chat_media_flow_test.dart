import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clay_dock/app/chat_voice_draft_controller.dart';
import 'package:clay_dock/l10n/app_localizations.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/ui/pages/notification/chat_media_draft.dart';
import 'package:clay_dock/ui/widgets/chat_voice_composer.dart';
import 'package:clay_dock/ui/widgets/v2/ui_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'test_app.dart';

ChatMessageDto receipt() => ChatMessageDto(
  id: 'sent',
  senderUserId: 'me',
  body: 'Voice message',
  createdAt: DateTime(2026),
  sequence: 1,
  mine: true,
);

class FakeRecorder implements ChatVoiceRecorder {
  Completer<bool>? permission;
  Completer<void>? startGate;
  Completer<void>? stopGate;
  bool allowed = true;
  int starts = 0, stops = 0, cancels = 0, disposals = 0;
  @override
  Future<bool> hasPermission() async =>
      permission == null ? allowed : permission!.future;
  @override
  Future<void> start(String path) async {
    starts++;
    await startGate?.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    await stopGate?.future;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class VoiceHarness {
  final recorder = FakeRecorder();
  final ids = <String>[];
  final deleted = <String>[];
  int sent = 0;
  int failures = 0;
  bool allowed = true;
  bool foreground = true;
  DateTime now = DateTime(2026);
  Completer<ChatMessageDto>? uploadGate;
  late final controller = ChatVoiceDraftController(
    recorder: recorder,
    canSend: () => allowed,
    isForeground: () => foreground,
    now: () => now,
    createFile: () async => File('isolated-recording.m4a'),
    deleteFile: (file) async {
      deleted.add(file.path);
    },
    upload: (file, clientId) async {
      ids.add(clientId);
      if (failures-- > 0) throw StateError('Isolated failed upload');
      return uploadGate == null ? receipt() : uploadGate!.future;
    },
    onSent: (_) => sent++,
  );
  void advance([int seconds = 3]) {
    now = now.add(Duration(seconds: seconds));
  }
}

void main() {
  testWidgets('hold release sends once and deletes only after success', (
    tester,
  ) async {
    final h = VoiceHarness();
    addTearDown(h.controller.dispose);
    await h.controller.start();
    h.advance();
    await h.controller.release();
    expect(h.recorder.starts, 1);
    expect(h.recorder.stops, 1);
    expect(h.ids, hasLength(1));
    expect(h.sent, 1);
    expect(h.deleted, ['isolated-recording.m4a']);
    expect(h.controller.phase, VoiceDraftPhase.idle);
  });

  testWidgets('cancel never uploads and removes the local recording', (
    tester,
  ) async {
    final h = VoiceHarness();
    addTearDown(h.controller.dispose);
    await h.controller.start();
    h.advance();
    await h.controller.cancel();
    await h.controller.release();
    expect(h.ids, isEmpty);
    expect(h.controller.file, isNull);
    expect(h.deleted, hasLength(1));
  });

  testWidgets(
    'lock retains recording after release then finishing sends automatically',
    (tester) async {
      final h = VoiceHarness();
      addTearDown(h.controller.dispose);
      await h.controller.start();
      h.controller.lock();
      h.advance();
      await h.controller.release();
      expect(h.controller.phase, VoiceDraftPhase.locked);
      expect(h.recorder.stops, 0);
      await h.controller.finishRecording();
      expect(h.controller.phase, VoiceDraftPhase.idle);
      expect(h.sent, 1);
      expect(h.ids, hasLength(1));
    },
  );

  testWidgets(
    'failed release send retains preview and retries same file and UUID',
    (tester) async {
      final h = VoiceHarness()..failures = 1;
      addTearDown(h.controller.dispose);
      await h.controller.start();
      h.advance();
      await h.controller.release();
      expect(h.controller.phase, VoiceDraftPhase.preview);
      expect(h.controller.error, VoiceDraftError.sending);
      expect(h.controller.file?.path, 'isolated-recording.m4a');
      expect(h.deleted, isEmpty);
      await h.controller.send();
      expect(h.ids, hasLength(2));
      expect(h.ids.toSet(), hasLength(1));
      expect(h.deleted, hasLength(1));
    },
  );

  testWidgets('releasing while permission is pending never starts or uploads', (
    tester,
  ) async {
    final h = VoiceHarness();
    addTearDown(h.controller.dispose);
    h.recorder.permission = Completer<bool>();
    final start = h.controller.start();
    final release = h.controller.release();
    h.recorder.permission!.complete(true);
    await start;
    await release;
    expect(h.recorder.starts, 0);
    expect(h.ids, isEmpty);
    expect(h.controller.active, isFalse);
  });

  testWidgets('cancel during native start waits and stops without sending', (
    tester,
  ) async {
    final h = VoiceHarness();
    addTearDown(h.controller.dispose);
    h.recorder.startGate = Completer<void>();
    final start = h.controller.start();
    await tester.pump();
    expect(h.recorder.starts, 1);
    final cancel = h.controller.cancel();
    h.recorder.startGate!.complete();
    await start;
    await cancel;
    expect(h.recorder.stops, 1);
    expect(h.ids, isEmpty);
    expect(h.deleted, hasLength(1));
  });

  testWidgets(
    'permission denial permits retry and unavailable media never starts',
    (tester) async {
      final h = VoiceHarness();
      addTearDown(h.controller.dispose);
      h.recorder.allowed = false;
      await h.controller.start();
      expect(h.controller.error, VoiceDraftError.recording);
      expect(h.recorder.starts, 0);
      h.recorder.allowed = true;
      h.allowed = false;
      await h.controller.start();
      expect(h.recorder.starts, 0);
      h.allowed = true;
      await h.controller.start(lock: true);
      expect(h.controller.phase, VoiceDraftPhase.locked);
      await h.controller.cancel();
    },
  );

  testWidgets(
    'interruption and removed access preserve a preview without uploading',
    (tester) async {
      final h = VoiceHarness();
      addTearDown(h.controller.dispose);
      await h.controller.start();
      h.advance();
      h.foreground = false;
      await h.controller.interrupt();
      expect(h.controller.phase, VoiceDraftPhase.preview);
      expect(h.ids, isEmpty);
      h.allowed = false;
      await h.controller.send();
      expect(h.ids, isEmpty);
      expect(h.controller.file, isNotNull);
      await h.controller.cancel();
    },
  );

  testWidgets('cancel while native Stop is pending suppresses release upload', (
    tester,
  ) async {
    final h = VoiceHarness();
    addTearDown(h.controller.dispose);
    await h.controller.start();
    h.advance();
    h.recorder.stopGate = Completer<void>();
    final release = h.controller.release();
    final cancel = h.controller.cancel();
    h.recorder.stopGate!.complete();
    await release;
    await cancel;
    expect(h.ids, isEmpty);
    expect(h.deleted, hasLength(1));
    expect(h.controller.phase, VoiceDraftPhase.idle);
  });

  testWidgets(
    'disposing during native startup releases recorder and removes file',
    (tester) async {
      final h = VoiceHarness();
      h.recorder.startGate = Completer<void>();
      final start = h.controller.start();
      await tester.pump();
      h.controller.dispose();
      h.recorder.startGate!.complete();
      await start;
      await tester.pump();
      expect(h.recorder.disposals, 1);
      expect(h.deleted, hasLength(1));
      expect(h.ids, isEmpty);
    },
  );

  for (final locked in [false, true]) {
    testWidgets(
      'one-minute limit sends ${locked ? 'locked' : 'held'} recording',
      (tester) async {
        final h = VoiceHarness();
        addTearDown(h.controller.dispose);
        await h.controller.start(lock: locked);
        h.advance(60);
        await tester.pump(const Duration(minutes: 1));
        expect(h.recorder.stops, 1);
        expect(h.ids, hasLength(1));
        expect(h.sent, 1);
        expect(h.controller.phase, VoiceDraftPhase.idle);
      },
    );
  }

  testWidgets(
    'locked Stop sends and a failed automatic send keeps a retry preview',
    (tester) async {
      final h = VoiceHarness()..failures = 1;
      addTearDown(h.controller.dispose);
      await h.controller.start(lock: true);
      h.advance();
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: h.controller,
              builder: (context, _) =>
                  ChatVoiceComposer(controller: h.controller, canSend: true),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      expect(h.ids, hasLength(1));
      expect(h.controller.phase, VoiceDraftPhase.preview);
      expect(h.controller.error, VoiceDraftError.sending);
      expect(h.deleted, isEmpty);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(h.ids, hasLength(2));
      expect(h.ids.toSet(), hasLength(1));
      expect(h.sent, 1);
      expect(h.controller.phase, VoiceDraftPhase.idle);
    },
  );

  for (final reason in ['background', 'access removed', 'upload failed']) {
    testWidgets('locked time limit preserves preview when $reason', (
      tester,
    ) async {
      final h = VoiceHarness();
      addTearDown(h.controller.dispose);
      await h.controller.start(lock: true);
      if (reason == 'background') h.foreground = false;
      if (reason == 'access removed') h.allowed = false;
      if (reason == 'upload failed') h.failures = 1;
      h.advance(60);
      await tester.pump(const Duration(minutes: 1));
      expect(h.recorder.stops, 1);
      expect(h.ids, hasLength(reason == 'upload failed' ? 1 : 0));
      expect(h.controller.phase, VoiceDraftPhase.preview);
      expect(h.controller.file, isNotNull);
      expect(h.deleted, isEmpty);
    });
  }

  testWidgets('an upload in flight cannot discard its file or submit again', (
    tester,
  ) async {
    final h = VoiceHarness();
    addTearDown(h.controller.dispose);
    h.uploadGate = Completer<ChatMessageDto>();
    await h.controller.start(lock: true);
    h.advance();
    await h.controller.stop();
    final send = h.controller.send();
    await h.controller.cancel();
    await h.controller.send();
    expect(h.deleted, isEmpty);
    expect(h.ids, hasLength(1));
    h.uploadGate!.complete(receipt());
    await send;
    expect(h.deleted, hasLength(1));
  });

  for (final gesture in ['release', 'cancel', 'lock', 'pointer cancel']) {
    testWidgets('microphone $gesture survives switching to the recording bar', (
      tester,
    ) async {
      final draft = TextEditingController();
      addTearDown(draft.dispose);
      var active = false;
      var starts = 0, releases = 0, cancels = 0, locks = 0, taps = 0;
      var armed = false;
      await tester.pumpWidget(
        localizedTestApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: MessageComposer(
                  controller: draft,
                  sending: false,
                  onSend: () {},
                  onEmoji: () {},
                  onVoice: () => taps++,
                  onVoiceHold: () {
                    starts++;
                    setState(() => active = true);
                  },
                  onVoiceRelease: () => releases++,
                  onVoiceCancel: () => cancels++,
                  onVoiceLock: () => locks++,
                  onVoiceCancelArmed: (value) => armed = value,
                  voiceBar: active
                      ? const SizedBox(height: 80, child: Text('Recording bar'))
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
      final origin = tester.getCenter(find.byIcon(Icons.mic_none));
      final pointer = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      expect(starts, 1);
      expect(find.text('Recording bar'), findsOneWidget);
      if (gesture == 'cancel') {
        await pointer.moveTo(origin - const Offset(100, 0));
        expect(armed, isTrue);
        expect(cancels, 0);
        expect(releases, 0);
      }
      if (gesture == 'lock') {
        await pointer.moveTo(origin - const Offset(0, 100));
      }
      if (gesture == 'pointer cancel') {
        await pointer.cancel();
      } else {
        await pointer.up();
      }
      await tester.pump();
      expect(taps, 0);
      expect(releases, gesture == 'release' ? 1 : 0);
      expect(
        cancels,
        gesture == 'cancel' || gesture == 'pointer cancel' ? 1 : 0,
      );
      expect(locks, gesture == 'lock' ? 1 : 0);
    });
  }

  testWidgets('left swipe opens trash while recording; moving back disarms', (
    tester,
  ) async {
    final h = VoiceHarness();
    final draft = TextEditingController();
    addTearDown(h.controller.dispose);
    addTearDown(draft.dispose);
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: h.controller,
              builder: (context, _) => MessageComposer(
                controller: draft,
                sending: false,
                onSend: () {},
                onEmoji: () {},
                onVoice: () => h.controller.start(lock: true),
                onVoiceHold: () => h.controller.start(),
                onVoiceRelease: h.controller.release,
                onVoiceCancel: h.controller.cancel,
                onVoiceLock: h.controller.lock,
                onVoiceCancelArmed: h.controller.armCancel,
                voiceBar: h.controller.active
                    ? ChatVoiceComposer(controller: h.controller, canSend: true)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
    final origin = tester.getCenter(find.byIcon(Icons.mic_none));
    final pointer = await tester.startGesture(origin);
    await tester.pump(const Duration(milliseconds: 600));
    h.advance();
    await pointer.moveTo(origin - const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 90));
    expect(h.controller.recording, isTrue);
    expect(h.controller.cancelArmed, isTrue);
    expect(h.recorder.stops, 0);
    expect(h.deleted, isEmpty);
    expect(h.ids, isEmpty);
    expect(find.byKey(const ValueKey('voice-cancel-armed')), findsOneWidget);
    await pointer.moveTo(origin);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(h.controller.cancelArmed, isFalse);
    expect(find.byKey(const ValueKey('voice-cancel-armed')), findsNothing);
    await pointer.up();
    await tester.pump();
    expect(h.ids, hasLength(1));
  });

  testWidgets('armed cancellation discards only on release and at time limit', (
    tester,
  ) async {
    for (final limit in [false, true]) {
      final h = VoiceHarness();
      await h.controller.start();
      h.advance();
      h.controller.armCancel(true);
      expect(h.recorder.stops, 0);
      expect(h.controller.recording, isTrue);
      if (limit) {
        h.advance(60);
        await tester.pump(const Duration(minutes: 1));
      } else {
        await h.controller.release();
      }
      expect(h.recorder.stops, 1);
      expect(h.ids, isEmpty);
      expect(h.deleted, hasLength(1));
      expect(h.controller.phase, VoiceDraftPhase.idle);
      h.controller.dispose();
    }
  });

  for (final locale in ['en', 'da']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        '$locale $brightness inline voice and camera fit compact enlarged text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = VoiceHarness();
          final draft = TextEditingController();
          addTearDown(h.controller.dispose);
          addTearDown(draft.dispose);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(brightness: brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedBuilder(
                    animation: h.controller,
                    builder: (context, _) => MessageComposer(
                      controller: draft,
                      sending: false,
                      onSend: () {},
                      onEmoji: () {},
                      onVoice: () {},
                      onCamera: () {},
                      onImage: () {},
                      onCeramic: () {},
                      voiceBar: h.controller.active
                          ? ChatVoiceComposer(
                              controller: h.controller,
                              canSend: true,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
          await h.controller.start();
          h.advance();
          await tester.pump();
          expect(tester.takeException(), isNull);
          h.controller.lock();
          await tester.pump();
          expect(find.byIcon(Icons.stop), findsOneWidget);
          await h.controller.stop();
          await tester.pump();
          expect(find.byIcon(Icons.play_arrow), findsOneWidget);
          expect(tester.takeException(), isNull);
          await h.controller.cancel();
          await tester.pump();
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets(
    'photo selection opens immediately and cancelling closes the draft',
    (tester) async {
      var picks = 0;
      await _openPhoto(
        tester,
        source: ImageSource.gallery,
        pick: (source) async {
          expect(source, ImageSource.gallery);
          picks++;
          return null;
        },
      );
      expect(picks, 1);
      expect(find.byType(ChatMediaDraft), findsNothing);
    },
  );

  testWidgets(
    'queued photo closes preview and transfers its file and full proportions',
    (tester) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('chat-photo-queue-'),
      ))!;
      final file = File('${dir.path}/preview.png');
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 10, 30),
          Paint()..color = Colors.blue,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(10, 30);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      });
      ChatImageDraft? queued;
      try {
        await _openPhoto(
          tester,
          source: ImageSource.gallery,
          pick: (_) async => file,
          onQueue: (draft) => queued = draft,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Send'));
        for (var attempt = 0; attempt < 20 && queued == null; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.byType(ChatMediaDraft), findsNothing);
        expect(queued, isNotNull);
        expect(queued!.file.path, file.path);
        expect(queued!.attachment.width, 10);
        expect(queued!.attachment.height, 30);
        expect(await tester.runAsync(file.exists), isTrue);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => dir.delete(recursive: true));
      }
    },
  );

  testWidgets(
    'camera opens directly and failed image send retains preview and retry UUID',
    (tester) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('chat-photo-flow-'),
      ))!;
      final file = File('${dir.path}/preview.png');
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 10, 20),
          Paint()..color = Colors.blue,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(10, 20);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      });
      final ids = <String>[];
      try {
        await _openPhoto(
          tester,
          source: ImageSource.camera,
          pick: (source) async {
            expect(source, ImageSource.camera);
            return file;
          },
          upload: (draft, id) async {
            expect(draft.path, file.path);
            ids.add(id);
            if (ids.length == 1) throw StateError('Isolated failed upload');
            return receipt();
          },
        );
        expect(find.byType(Image), findsOneWidget);
        // Complete the decoder's file reads outside the widget fake clock.
        for (var attempt = 0; attempt < 3; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        await tester.tap(find.widgetWithText(FilledButton, 'Send'));
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);
        expect(await tester.runAsync(file.exists), isTrue);
        await tester.tap(find.widgetWithText(FilledButton, 'Send'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
        expect(ids.toSet(), hasLength(1));
        expect(find.byType(ChatMediaDraft), findsNothing);
        expect(await tester.runAsync(file.exists), isFalse);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.runAsync(() => dir.delete(recursive: true));
      }
    },
  );
}

Future<void> _openPhoto(
  WidgetTester tester, {
  required ImageSource source,
  required Future<File?> Function(ImageSource) pick,
  Future<ChatMessageDto> Function(File, String)? upload,
  ValueChanged<ChatImageDraft>? onQueue,
}) async {
  await tester.pumpWidget(
    localizedTestApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChatMediaDraft(
                conversation: 'isolated',
                source: source,
                pickImage: pick,
                upload: upload,
                onQueue: onQueue,
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
}
