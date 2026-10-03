import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';

class ChatMediaFiles {
  static Directory? _directory;
  static Future<Directory> directory() async {
    return _directory ??= await Directory(
      '${(await getTemporaryDirectory()).path}/chat-media',
    ).create(recursive: true);
  }

  static Future<File> create(String extension) async =>
      File('${(await directory()).path}/${createClientUuid()}.$extension');
  static Future<void> clear() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final dir = await directory();
    for (final entry in await dir.list().toList()) {
      if (entry is File) {
        try {
          await entry.delete();
        } catch (_) {
          /* Retry on startup. */
        }
      }
    }
  }
}

class ChatPlaybackController extends ChangeNotifier
    with WidgetsBindingObserver {
  ChatPlaybackController._();
  static final instance = ChatPlaybackController._();
  AudioPlayer? _player;
  String? path;
  bool playing = false;
  bool _observing = false;
  Future<void> _operations = Future<void>.value();
  int _playGeneration = 0;
  Future<void> _queue(Future<void> Function() action) {
    final next = _operations.then((_) => action());
    _operations = next.catchError((_) {});
    return next;
  }

  Future<void> toggle(File file) => _queue(() => _toggle(file));
  Future<void> _toggle(File file) async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    final player = _player ??= AudioPlayer();
    if (path == file.path && player.playing) {
      await _pause();
      return;
    }
    await _pause();
    if (path != file.path) await player.setFilePath(file.path);
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    path = file.path;
    final generation = ++_playGeneration;
    playing = true;
    notifyListeners();
    unawaited(
      player
          .play()
          .then((_) {
            if (generation == _playGeneration) {
              playing = false;
              notifyListeners();
            }
          })
          .catchError((_) {
            if (generation == _playGeneration) {
              playing = false;
              notifyListeners();
            }
          }),
    );
  }

  Future<void> pause() => _queue(_pause);
  Future<void> _pause() async {
    _playGeneration++;
    await _player?.pause();
    playing = false;
    notifyListeners();
  }

  Future<void> reset() => _queue(() async {
    await _pause();
    await _player?.dispose();
    _player = null;
    path = null;
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(pause());
  }
}

class ChatMediaDownload {
  static final Map<String, Future<File>> _pending = {};
  static final Map<String, CancelToken> _tokens = {};
  static Future<File> fetch(String conversation, String message, String type) =>
      _pending.putIfAbsent('$conversation/$message', () async {
        final key = '$conversation/$message';
        final token = CancelToken();
        _tokens[key] = token;
        final file = await ChatMediaFiles.create(
          type == 'IMAGE' ? 'jpg' : 'm4a',
        );
        try {
          if (token.isCancelled) {
            throw const FileSystemException('Attachment unavailable');
          }
          await ChatRepository.downloadAttachment(
            conversation,
            message,
            file,
            token,
          );
          return file;
        } catch (_) {
          if (identical(_tokens[key], token)) _pending.remove(key);
          rethrow;
        } finally {
          if (identical(_tokens[key], token)) _tokens.remove(key);
        }
      });
  static Future<void> clear() async {
    final pending = _pending.values.toList();
    for (final token in _tokens.values) {
      token.cancel();
    }
    _tokens.clear();
    _pending.clear();
    await Future.wait(
      pending.map((value) => value.then<void>((_) {}, onError: (_) {})),
    );
    await ChatPlaybackController.instance.reset();
    await ChatMediaFiles.clear();
  }
}
