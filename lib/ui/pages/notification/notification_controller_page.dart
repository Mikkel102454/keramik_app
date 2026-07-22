import 'dart:async';

import 'package:ceramic_app/api/chat_event_service.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/chat_event_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_badge_controller.dart';
import 'package:flutter/material.dart';

class NotificationControllerPage extends ChangeNotifier {
  NotificationControllerPage() {
    _eventSubscription = ChatEventService.instance.events.listen(_handleEvent);
  }

  late final StreamSubscription<ChatEventDto> _eventSubscription;
  bool _disposed = false;
  bool _isLoading = false;
  String? _error;
  List<FriendRequestDto> incoming = const [];
  List<FriendRequestDto> outgoing = const [];
  List<DirectConversationDto> conversations = const [];
  String? incomingCursor;
  String? outgoingCursor;
  String? conversationCursor;
  bool isLoadingMore = false;
  bool _reloadQueued = false;

  void _handleEvent(ChatEventDto event) {
    if (_disposed) return;
    if (_isLoading) {
      _reloadQueued = true;
      return;
    }
    unawaited(load());
  }

  Future<void> load() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      final pages = await Future.wait([
        SocialRepository.getRequests('incoming'),
        SocialRepository.getRequests('outgoing'),
        ChatRepository.getConversations(),
      ]);
      final incomingPage = pages[0] as CursorPage<FriendRequestDto>;
      final outgoingPage = pages[1] as CursorPage<FriendRequestDto>;
      final conversationPage = pages[2] as CursorPage<DirectConversationDto>;
      incoming = incomingPage.items;
      incomingCursor = incomingPage.nextCursor;
      outgoing = outgoingPage.items;
      outgoingCursor = outgoingPage.nextCursor;
      conversations = conversationPage.items;
      conversationCursor = conversationPage.nextCursor;
      unawaited(NavigationBadgeController.instance.refresh());
    } catch (exception) {
      _error = exception.toString();
    } finally {
      _isLoading = false;
      _notifySafely();
      if (_reloadQueued && !_disposed) {
        _reloadQueued = false;
        unawaited(load());
      }
    }
  }

  Future<void> loadMoreConversations() async {
    if (_disposed || isLoadingMore || conversationCursor == null) return;
    isLoadingMore = true;
    _notifySafely();
    try {
      final page = await ChatRepository.getConversations(
        cursor: conversationCursor,
      );
      conversations = [...conversations, ...page.items];
      conversationCursor = page.nextCursor;
    } catch (exception) {
      _error = exception.toString();
    } finally {
      isLoadingMore = false;
      _notifySafely();
    }
  }

  Future<DirectConversationDto> acceptMessageRequest(String id) async {
    final accepted = await ChatRepository.accept(id);
    await load();
    return accepted;
  }

  Future<void> declineMessageRequest(String id) async {
    await ChatRepository.decline(id);
    await load();
  }

  List<DirectConversationDto> get incomingMessageRequests => conversations
      .where((item) => item.status == 'PENDING' && item.incomingRequest)
      .toList();

  int get requestCount => incoming.length + incomingMessageRequests.length;

  Future<void> accept(String requestId) async {
    if (_disposed) return;
    await SocialRepository.acceptFriendRequest(requestId);
    await load();
  }

  Future<void> decline(String requestId) async {
    if (_disposed) return;
    await SocialRepository.declineFriendRequest(requestId);
    await load();
  }

  Future<void> loadMore(String direction) async {
    if (_disposed) return;
    final cursor = direction == 'incoming' ? incomingCursor : outgoingCursor;
    if (cursor == null) return;
    try {
      final page = await SocialRepository.getRequests(
        direction,
        cursor: cursor,
      );
      if (direction == 'incoming') {
        incoming = [...incoming, ...page.items];
        incomingCursor = page.nextCursor;
      } else {
        outgoing = [...outgoing, ...page.items];
        outgoingCursor = page.nextCursor;
      }
    } catch (exception) {
      _error = exception.toString();
    }
    _notifySafely();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

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
