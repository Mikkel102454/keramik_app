import 'package:ceramic_app/utils/network_timeout.dart';
import 'dart:async';
import 'dart:io';

import 'package:ceramic_app/api/chat_event_service.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/chat_event_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:ceramic_app/ui/pages/notification/local_chat_send.dart';
import 'package:flutter/foundation.dart';

class ConversationPageController extends ChangeNotifier {
  ConversationPageController(this.conversation) {
    _eventSubscription = ChatEventService.instance.events.listen(_handleEvent);
  }

  DirectConversationDto conversation;
  late final StreamSubscription<ChatEventDto> _eventSubscription;
  List<ChatMessageDto> messages = const [];
  final List<LocalChatSend> localSends = [];
  String? beforeCursor;
  String? error;
  bool isLoading = false;
  bool isLoadingOlder = false;
  bool isSending = false;
  int sentRevision = 0;
  bool _disposed = false;
  bool _liveReloading = false;
  bool _liveReloadQueued = false;
  final Map<int, String> _ceramicClientIds = {};
  final Map<String, String> _textClientIds = {};
  bool get hasPendingTextSend => _textClientIds.isNotEmpty;
  bool get canRetryPendingText =>
      conversation.status == 'PENDING' &&
      !conversation.incomingRequest &&
      hasPendingTextSend;
  bool hasPendingCeramicSend(int ceramicId) =>
      _ceramicClientIds.containsKey(ceramicId);

  void _handleEvent(ChatEventDto event) {
    if (_disposed) return;
    if (!event.reconcileOnly &&
        event.type != 'SYNC_REQUIRED' &&
        event.conversationId != conversation.id) {
      return;
    }
    if (isLoading || _liveReloading || isSending) {
      _liveReloadQueued = true;
      return;
    }
    unawaited(_reconcileLive());
  }

  Future<void> load() async {
    if (_disposed) return;
    isLoading = true;
    error = null;
    _notifySafely();
    try {
      if (conversation.isDraft) {
        final resolved = await ChatRepository.resolveDirect(
          conversation.otherUser!.userId,
        );
        conversation =
            resolved.conversation ??
            DirectConversationDto.draft(resolved.otherUser);
        if (conversation.isDraft) return;
      }
      final results = await Future.wait([
        ChatRepository.getConversation(conversation.id),
        ChatRepository.getMessages(conversation.id),
      ]);
      conversation = results[0] as DirectConversationDto;
      final page = results[1] as ChatMessagePageDto;
      _mergeLatestPage(page);
      _replaceAcknowledgedFirstSend();
      await _markLatestRead();
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoading = false;
      _notifySafely();
      if (_liveReloadQueued && !_disposed) {
        _liveReloadQueued = false;
        unawaited(_reconcileLive());
      }
    }
  }

  Future<void> _reconcileLive() async {
    if (_disposed || _liveReloading) return;
    if (conversation.isDraft) {
      await load();
      return;
    }
    _liveReloading = true;
    try {
      final results = await Future.wait([
        ChatRepository.getConversation(conversation.id),
        ChatRepository.getMessages(conversation.id),
      ]);
      conversation = results[0] as DirectConversationDto;
      final page = results[1] as ChatMessagePageDto;
      _mergeLatestPage(page);
      _replaceAcknowledgedFirstSend();
      error = null;
      await _markLatestRead();
    } catch (exception) {
      error = exception.toString();
    } finally {
      _liveReloading = false;
      _notifySafely();
      if (_liveReloadQueued && !_disposed) {
        _liveReloadQueued = false;
        unawaited(_reconcileLive());
      }
    }
  }

  Future<void> loadOlder() async {
    final cursor = beforeCursor;
    if (_disposed || isLoadingOlder || cursor == null) return;
    isLoadingOlder = true;
    error = null;
    _notifySafely();
    try {
      final page = await ChatRepository.getMessages(
        conversation.id,
        before: cursor,
      );
      _mergeMessages(page.items);
      beforeCursor = page.nextCursor;
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoadingOlder = false;
      _notifySafely();
    }
  }

  void _mergeMessages(List<ChatMessageDto> items) {
    final byId = {for (final message in messages) message.id: message};
    for (final message in items) {
      byId[message.id] = message;
    }
    messages = byId.values.toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
  }

  void _mergeLatestPage(ChatMessagePageDto page) {
    // Refresh only the latest bounded page without discarding history already
    // loaded on demand or moving its older-page cursor forward.
    final oldest = messages.firstOrNull?.sequence;
    if (page.items.isEmpty) {
      messages = const [];
      beforeCursor = page.nextCursor;
      return;
    }
    _mergeMessages(page.items);
    if (oldest == null || oldest >= page.items.first.sequence) {
      beforeCursor = page.nextCursor;
    }
  }

  Future<bool> send(String rawBody) async {
    final body = rawBody.trim();
    if (_disposed ||
        isSending ||
        isLoading ||
        _liveReloading ||
        body.isEmpty ||
        (conversation.readOnly &&
            !(canRetryPendingText && _textClientIds.containsKey(body)))) {
      return false;
    }
    isSending = true;
    error = null;
    final clientId = _textClientIds.putIfAbsent(body, createClientUuid);
    final pending = _beginSend(
      clientId: clientId,
      body: body,
      retry: () async {
        await send(body);
      },
    );
    try {
      if (conversation.isDraft) {
        conversation = await ChatRepository.sendDirect(
          conversation.otherUser!.userId,
          clientId,
          body,
        );
        _textClientIds.remove(body);
        pending.acknowledged = true;
        await load();
        sentRevision++;
      } else {
        final sent = await ChatRepository.send(conversation.id, clientId, body);
        _textClientIds.remove(body);
        localSends.remove(pending);
        final isNew = !messages.any((message) => message.id == sent.id);
        recordSentMessage(sent);
        if (isNew) {
          if (conversation.status == 'PENDING') {
            final remaining = (conversation.requestMessagesRemaining - 1).clamp(
              0,
              3,
            );
            conversation = conversation.copyWith(
              requestMessagesRemaining: remaining,
              readOnly: remaining == 0,
            );
          }
        }
        await _reconcileLive();
      }
      return true;
    } catch (exception) {
      _failSend(pending, exception);
      if (!localSends.contains(pending)) error = exception.toString();
      return false;
    } finally {
      isSending = false;
      pending.inFlight = false;
      _notifySafely();
      if (_liveReloadQueued && !_disposed) {
        _liveReloadQueued = false;
        unawaited(_reconcileLive());
      }
    }
  }

  Future<bool> sendCeramic(int ceramicId, {ChatCeramicCardDto? preview}) async {
    if (_disposed || isSending || !conversation.canShare) return false;
    isSending = true;
    error = null;
    final clientId = _ceramicClientIds.putIfAbsent(ceramicId, createClientUuid);
    final pending = _beginSend(
      clientId: clientId,
      type: 'CERAMIC',
      ceramic: preview,
      retry: () async {
        await sendCeramic(ceramicId, preview: preview);
      },
    );
    try {
      final sent = await ChatRepository.sendCeramic(
        conversation.id,
        clientId,
        ceramicId,
      );
      _ceramicClientIds.remove(ceramicId);
      localSends.remove(pending);
      recordSentMessage(sent);
      return true;
    } catch (exception) {
      _failSend(pending, exception);
      return false;
    } finally {
      isSending = false;
      pending.inFlight = false;
      _notifySafely();
      _flushQueuedReload();
    }
  }

  /// Uploads remain authenticated and idempotent. Only the preview is local.
  Future<ChatMessageDto> sendAttachment(
    File file,
    String clientId,
    ChatAttachmentDto attachment, {
    bool ownsFile = false,
    Future<void> Function()? retry,
  }) async {
    if (_disposed || isSending || !conversation.canShare) {
      if (ownsFile && !localSends.any((send) => send.clientId == clientId)) {
        await _deleteFile(file);
      }
      throw StateError('Media sending unavailable');
    }
    isSending = true;
    error = null;
    final pending = _beginSend(
      clientId: clientId,
      type: attachment.type,
      attachment: attachment,
      file: file,
      ownsFile: ownsFile,
      retry:
          retry ??
          () async {
            await sendAttachment(
              file,
              clientId,
              attachment,
              ownsFile: ownsFile,
            );
          },
    );
    try {
      final sent = await ChatRepository.sendAttachment(
        conversation.id,
        clientId,
        attachment.type,
        file,
      );
      localSends.remove(pending);
      recordSentMessage(sent);
      if (ownsFile) await _deleteFile(file);
      return sent;
    } catch (exception) {
      _failSend(pending, exception);
      rethrow;
    } finally {
      pending.inFlight = false;
      isSending = false;
      if (_disposed && ownsFile) await _deleteFile(file);
      _notifySafely();
      _flushQueuedReload();
    }
  }

  void _failSend(LocalChatSend pending, Object error) {
    pending.failed = true;
    pending.unconfirmed = isNetworkTimeout(error);
    // Failure details add height; keep the Retry action above the keyboard.
    if (localSends.contains(pending)) sentRevision++;
  }

  LocalChatSend _beginSend({
    required String clientId,
    required Future<void> Function() retry,
    String body = '',
    String type = 'TEXT',
    ChatCeramicCardDto? ceramic,
    ChatAttachmentDto? attachment,
    File? file,
    bool ownsFile = false,
  }) {
    final existing = localSends.where((send) => send.clientId == clientId);
    final pending = existing.isNotEmpty
        ? existing.first
        : LocalChatSend(
            clientId: clientId,
            retry: retry,
            file: file,
            ownsFile: ownsFile,
            message: ChatMessageDto(
              id: 'local-$clientId',
              senderUserId: '',
              body: body,
              createdAt: DateTime.now(),
              sequence: 0,
              mine: true,
              type: type,
              ceramic: ceramic,
              attachment: attachment,
            ),
          );
    if (existing.isEmpty) localSends.add(pending);
    pending.failed = false;
    pending.unconfirmed = false;
    pending.inFlight = true;
    sentRevision++;
    _notifySafely();
    return pending;
  }

  Future<void> retryLocalSend(LocalChatSend pending) async {
    if (_disposed ||
        isSending ||
        !pending.failed ||
        !localSends.contains(pending)) {
      return;
    }
    try {
      await pending.retry();
    } catch (_) {
      // The send path keeps the preview and failure state for another retry.
    }
  }

  bool canRetryLocalSend(LocalChatSend pending) =>
      !isSending &&
      !isLoading &&
      pending.failed &&
      (pending.message.type == 'TEXT'
          ? !conversation.readOnly ||
                (canRetryPendingText &&
                    _textClientIds.containsKey(pending.message.body))
          : conversation.canShare);

  void _replaceAcknowledgedFirstSend() {
    localSends.removeWhere(
      (pending) =>
          pending.acknowledged &&
          messages.any(
            (message) =>
                message.mine &&
                message.type == 'TEXT' &&
                message.body == pending.message.body,
          ),
    );
  }

  void removeLocalFile(File file) {
    localSends.removeWhere((send) => send.file?.path == file.path);
    _notifySafely();
  }

  void _flushQueuedReload() {
    if (_liveReloadQueued && !_disposed) {
      _liveReloadQueued = false;
      unawaited(_reconcileLive());
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
    } catch (_) {
      /* Startup recovery retries. */
    }
  }

  Future<void> archive() => ChatRepository.archive(conversation.id);

  /// Accept an acknowledged local send before refreshing over REST.
  /// Incoming reconciliation never advances this revision. Local enqueue does.
  void recordSentMessage(ChatMessageDto sent) {
    if (_disposed) return;
    if (!messages.any((message) => message.id == sent.id)) {
      messages = [...messages, sent]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
    }
    sentRevision++;
    _notifySafely();
  }

  Future<void> _markLatestRead() async {
    if (messages.isEmpty) return;
    await ChatRepository.markRead(conversation.id, messages.last.id);
    conversation = conversation.copyWith(unreadCount: 0);
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _eventSubscription.cancel();
    for (final pending in localSends) {
      if (pending.ownsFile && !pending.inFlight && pending.file != null) {
        unawaited(_deleteFile(pending.file!));
      }
    }
    super.dispose();
  }
}
