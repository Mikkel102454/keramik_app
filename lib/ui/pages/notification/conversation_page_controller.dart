import 'dart:async';

import 'package:ceramic_app/api/chat_event_service.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/chat_event_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:flutter/foundation.dart';

class ConversationPageController extends ChangeNotifier {
  ConversationPageController(this.conversation) {
    _eventSubscription = ChatEventService.instance.events.listen(_handleEvent);
  }

  DirectConversationDto conversation;
  late final StreamSubscription<ChatEventDto> _eventSubscription;
  List<ChatMessageDto> messages = const [];
  String? beforeCursor;
  String? error;
  bool isLoading = false;
  bool isLoadingOlder = false;
  bool isSending = false;
  bool _disposed = false;
  bool _liveReloading = false;
  bool _liveReloadQueued = false;
  final Map<int, String> _ceramicClientIds = {};

  void _handleEvent(ChatEventDto event) {
    if (_disposed) return;
    if (!event.reconcileOnly &&
        event.type != 'SYNC_REQUIRED' &&
        event.conversationId != conversation.id) {
      return;
    }
    if (isLoading || _liveReloading) {
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
      final results = await Future.wait([
        ChatRepository.getConversation(conversation.id),
        ChatRepository.getMessages(conversation.id),
      ]);
      conversation = results[0] as DirectConversationDto;
      final page = results[1] as ChatMessagePageDto;
      messages = page.items;
      beforeCursor = page.nextCursor;
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
    _liveReloading = true;
    try {
      final results = await Future.wait([
        ChatRepository.getConversation(conversation.id),
        ChatRepository.getMessages(conversation.id),
      ]);
      conversation = results[0] as DirectConversationDto;
      final page = results[1] as ChatMessagePageDto;
      final byId = <String, ChatMessageDto>{
        for (final message in messages) message.id: message,
      };
      for (final message in page.items) {
        byId[message.id] = message;
      }
      messages = byId.values.toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      if (messages.length == page.items.length) beforeCursor = page.nextCursor;
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
    _notifySafely();
    try {
      final page = await ChatRepository.getMessages(
        conversation.id,
        before: cursor,
      );
      messages = [...page.items, ...messages];
      beforeCursor = page.nextCursor;
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoadingOlder = false;
      _notifySafely();
    }
  }

  Future<bool> send(String rawBody) async {
    final body = rawBody.trim();
    if (_disposed || isSending || body.isEmpty || conversation.readOnly) {
      return false;
    }
    isSending = true;
    error = null;
    _notifySafely();
    try {
      final sent = await ChatRepository.send(
        conversation.id,
        createClientUuid(),
        body,
      );
      messages = [...messages, sent];
      return true;
    } catch (exception) {
      error = exception.toString();
      return false;
    } finally {
      isSending = false;
      _notifySafely();
    }
  }

  Future<bool> sendCeramic(int ceramicId) async {
    if (_disposed || isSending || conversation.readOnly) return false;
    isSending = true;
    error = null;
    _notifySafely();
    final clientId = _ceramicClientIds.putIfAbsent(ceramicId, createClientUuid);
    try {
      final sent = await ChatRepository.sendCeramic(
        conversation.id,
        clientId,
        ceramicId,
      );
      _ceramicClientIds.remove(ceramicId);
      messages = [...messages, sent];
      return true;
    } catch (exception) {
      error = exception.toString();
      return false;
    } finally {
      isSending = false;
      _notifySafely();
    }
  }

  Future<void> archive() => ChatRepository.archive(conversation.id);

  Future<void> _markLatestRead() async {
    if (messages.isEmpty) return;
    await ChatRepository.markRead(conversation.id, messages.last.id);
    conversation = DirectConversationDto(
      id: conversation.id,
      status: conversation.status,
      type: conversation.type,
      title: conversation.title,
      avatarInitials: conversation.avatarInitials,
      avatarColor: conversation.avatarColor,
      memberCount: conversation.memberCount,
      otherUser: conversation.otherUser,
      lastMessagePreview: conversation.lastMessagePreview,
      lastMessageType: conversation.lastMessageType,
      lastMessageAt: conversation.lastMessageAt,
      unreadCount: 0,
      archived: conversation.archived,
      incomingRequest: conversation.incomingRequest,
      readOnly: conversation.readOnly,
      readOnlyReason: conversation.readOnlyReason,
    );
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _eventSubscription.cancel();
    super.dispose();
  }
}
