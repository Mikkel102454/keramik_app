import 'package:clay_dock/utils/network_timeout.dart';
import 'dart:async';
import 'dart:io';

import 'package:clay_dock/app/chat_media_controller.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/utils/client_uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

enum VoiceDraftPhase {
  idle,
  starting,
  recording,
  locked,
  stopping,
  preview,
  sending,
}

enum VoiceDraftError { recording, sending }

enum _Finish { discard, preview, send }

abstract class ChatVoiceRecorder {
  Future<bool> hasPermission();
  Future<void> start(String path);
  Future<void> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class DeviceChatVoiceRecorder implements ChatVoiceRecorder {
  AudioRecorder? _recorder;
  AudioRecorder get _device => _recorder ??= AudioRecorder();
  @override
  Future<bool> hasPermission() => _device.hasPermission();
  @override
  Future<void> start(String path) async {
    await ChatPlaybackController.instance.pause();
    await _device.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: path,
    );
  }

  @override
  Future<void> stop() async {
    await _device.stop();
  }

  @override
  Future<void> cancel() => _device.cancel();
  @override
  Future<void> dispose() async {
    await _recorder?.dispose();
  }
}

/// One local recording, with a stable UUID until upload succeeds or is discarded.
class ChatVoiceDraftController extends ChangeNotifier {
  ChatVoiceDraftController({
    required this.upload,
    required this.canSend,
    required this.onSent,
    this.onDiscard,
    ChatVoiceRecorder? recorder,
    Future<File> Function()? createFile,
    Future<void> Function(File)? deleteFile,
    bool Function()? isForeground,
    DateTime Function()? now,
  }) : _recorder = recorder ?? DeviceChatVoiceRecorder(),
       _createFile = createFile ?? (() => ChatMediaFiles.create('m4a')),
       _deleteFile =
           deleteFile ??
           ((file) async {
             try {
               await file.delete();
             } catch (_) {
               /* Startup cleanup retries. */
             }
           }),
       _isForeground = isForeground ?? (() => true),
       _now = now ?? DateTime.now;

  final Future<ChatMessageDto> Function(File, String) upload;
  final bool Function() canSend;
  final ValueChanged<ChatMessageDto> onSent;
  final ValueChanged<File>? onDiscard;
  final ChatVoiceRecorder _recorder;
  final Future<File> Function() _createFile;
  final Future<void> Function(File) _deleteFile;
  final bool Function() _isForeground;
  final DateTime Function() _now;
  VoiceDraftPhase phase = VoiceDraftPhase.idle;
  VoiceDraftError? error;
  bool sendTimedOut = false;
  File? file;
  Duration duration = Duration.zero;
  bool cancelArmed = false;
  String? _clientId;
  DateTime? _startedAt;
  Timer? _ticker;
  Timer? _limit;
  bool _disposed = false;
  bool _discardRequested = false;
  bool _lockRequested = false;
  Future<void>? _starting;
  Future<void>? _finishing;
  Future<void>? _sending;

  bool get active => phase != VoiceDraftPhase.idle || error != null;
  bool get recording =>
      phase == VoiceDraftPhase.recording || phase == VoiceDraftPhase.locked;
  bool get locked => phase == VoiceDraftPhase.locked || _lockRequested;

  Future<void> start({bool lock = false}) {
    if (_disposed || phase != VoiceDraftPhase.idle || !canSend()) {
      return Future.value();
    }
    _discardRequested = false;
    cancelArmed = false;
    _lockRequested = lock;
    error = null;
    duration = Duration.zero;
    _clientId = createClientUuid();
    phase = VoiceDraftPhase.starting;
    _notify();
    return _starting = _start();
  }

  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        throw StateError('Permission unavailable');
      }
      // Permission activities can complete just before the resumed event.
      for (
        var attempt = 0;
        !_isForeground() && !_discardRequested && !_disposed && attempt < 20;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (_disposed || _discardRequested || !_isForeground() || !canSend()) {
        await _discard();
        return;
      }
      file = await _createFile();
      if (_disposed || _discardRequested || !_isForeground() || !canSend()) {
        await _discard();
        return;
      }
      await _recorder.start(file!.path);
      _startedAt = _now();
      phase = _lockRequested
          ? VoiceDraftPhase.locked
          : VoiceDraftPhase.recording;
      if (_disposed || _discardRequested) {
        await _finish(_Finish.discard);
      } else if (!_isForeground() || !canSend()) {
        await _finish(_Finish.preview);
      } else {
        _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
          _updateDuration();
          _notify();
        });
        _limit = Timer(const Duration(minutes: 1), () {
          unawaited(_finish(cancelArmed ? _Finish.discard : _Finish.send));
        });
        _notify();
      }
    } catch (_) {
      try {
        await _recorder.cancel();
      } catch (_) {
        /* Release on disposal. */
      }
      await _discard();
      if (!_discardRequested && !_disposed) error = VoiceDraftError.recording;
      _notify();
    }
  }

  void lock() {
    if (phase != VoiceDraftPhase.starting &&
        phase != VoiceDraftPhase.recording) {
      return;
    }
    _lockRequested = true;
    cancelArmed = false;
    if (recording) phase = VoiceDraftPhase.locked;
    _notify();
  }

  Future<void> release() {
    if (cancelArmed) return cancel();
    if (locked) return Future.value();
    // Releasing during permission/startup must never begin an unattended clip.
    if (phase == VoiceDraftPhase.starting) return cancel();
    return _finish(_Finish.send);
  }

  Future<void> stop() => _finish(_Finish.preview);

  Future<void> finishRecording() => _finish(_Finish.send);

  void armCancel(bool armed) {
    if (locked || (phase != VoiceDraftPhase.starting && !recording)) return;
    if (cancelArmed == armed) return;
    cancelArmed = armed;
    _notify();
  }

  Future<void> interrupt() {
    if (phase == VoiceDraftPhase.starting) return cancel();
    return recording ? stop() : Future.value();
  }

  Future<void> cancel() async {
    if (phase == VoiceDraftPhase.sending) return;
    _discardRequested = true;
    if (phase == VoiceDraftPhase.starting) {
      await _starting;
    } else if (phase == VoiceDraftPhase.stopping) {
      await _finishing;
    } else if (recording) {
      await _finish(_Finish.discard);
    } else {
      await _discard();
    }
  }

  void _updateDuration() {
    final start = _startedAt;
    if (start != null) {
      final milliseconds = _now()
          .difference(start)
          .inMilliseconds
          .clamp(0, 60000);
      duration = Duration(milliseconds: milliseconds);
    }
  }

  Future<void> _finish(_Finish action) {
    if (!recording) return Future.value();
    _updateDuration();
    _ticker?.cancel();
    _limit?.cancel();
    phase = VoiceDraftPhase.stopping;
    _notify();
    return _finishing = _stopRecording(action);
  }

  Future<void> _stopRecording(_Finish action) async {
    try {
      await _recorder.stop();
      if (_disposed ||
          _discardRequested ||
          action == _Finish.discard ||
          duration < const Duration(milliseconds: 300)) {
        await _discard();
        return;
      }
      phase = VoiceDraftPhase.preview;
      _notify();
      if (action == _Finish.send && _isForeground()) await send();
    } catch (_) {
      try {
        await _recorder.cancel();
      } catch (_) {
        /* Release on disposal. */
      }
      await _discard();
      if (!_disposed && !_discardRequested) error = VoiceDraftError.recording;
      _notify();
    }
  }

  Future<void> send() {
    final draft = file;
    final clientId = _clientId;
    if (_disposed ||
        phase != VoiceDraftPhase.preview ||
        draft == null ||
        clientId == null ||
        !canSend()) {
      return Future.value();
    }
    phase = VoiceDraftPhase.sending;
    error = null;
    sendTimedOut = false;
    _notify();
    return _sending = _upload(draft, clientId);
  }

  Future<void> _upload(File draft, String clientId) async {
    try {
      final sent = await upload(draft, clientId);
      await _discard();
      if (!_disposed) onSent(sent);
    } catch (exception) {
      sendTimedOut = isNetworkTimeout(exception);
      phase = VoiceDraftPhase.preview;
      error = VoiceDraftError.sending;
      _notify();
    }
  }

  Future<void> _discard() async {
    _ticker?.cancel();
    _limit?.cancel();
    final draft = file;
    file = null;
    if (draft != null) {
      if (!_disposed) onDiscard?.call(draft);
      await _deleteFile(draft);
    }
    _startedAt = null;
    _clientId = null;
    error = null;
    phase = VoiceDraftPhase.idle;
    cancelArmed = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _cleanup() async {
    await _starting;
    await _finishing;
    await _sending;
    if (recording) {
      try {
        await _recorder.cancel();
      } catch (_) {
        /* Startup recovery retries. */
      }
    }
    try {
      await _recorder.dispose();
    } catch (_) {
      /* Startup cleanup retries. */
    }
    await _discard();
  }

  @override
  void dispose() {
    _disposed = true;
    _discardRequested = true;
    _ticker?.cancel();
    _limit?.cancel();
    unawaited(_cleanup());
    super.dispose();
  }
}
