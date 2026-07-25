import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/ui/pages/notification/archived_conversations_page.dart';
import 'package:ceramic_app/ui/pages/notification/chat_requests_page.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page.dart';
import 'package:ceramic_app/ui/pages/notification/new_group_page.dart';
import 'package:ceramic_app/ui/pages/notification/notification_controller_page.dart';
import 'package:ceramic_app/ui/pages/profile/user_search_page.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:intl/intl.dart';

enum _InboxFilter { all, unread, groups }

@RoutePage()
class NotificationPage extends StatefulWidget {
  final NotificationControllerPage? controller;

  const NotificationPage({super.key, this.controller});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final NotificationControllerPage _controller =
      widget.controller ?? NotificationControllerPage();
  late final bool _ownsController = widget.controller == null;
  _InboxFilter _filter = _InboxFilter.all;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _openRequests() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatRequestsPage(controller: _controller)),
    );
    if (mounted) await _controller.load();
  }

  Future<void> _openConversation(DirectConversationDto conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConversationPage(initialConversation: conversation)),
    );
    if (mounted) await _controller.load();
  }

  Future<void> _selectMenu(String value) async {
    if (value == 'archive') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedConversationsPage()));
      if (mounted) await _controller.load();
    } else if (value == 'group' && mounted) {
      final group = await Navigator.push<DirectConversationDto>(
        context,
        MaterialPageRoute(builder: (_) => const NewGroupPage()),
      );
      if (!mounted || group == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConversationPage(initialConversation: group)),
      );
      if (mounted) await _controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(context.l10n.chats),
        actions: [
          IconButton(
            tooltip: context.l10n.searchAccounts,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSearchPage())),
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<String>(
            onSelected: _selectMenu,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'group',
                child: Text(context.l10n.newGroup),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(context.l10n.archivedChats),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.error != null && _controller.conversations.isEmpty) {
              return _InboxRetry(message: _controller.error!, onRetry: _controller.load);
            }
            final conversations = _visibleConversations();
            return RefreshIndicator(
              onRefresh: _controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 18),
                children: [
                  _RequestBanner(
                    count: AppSettingsController
                            .instance
                            .settings
                            .notifyMessageRequests
                        ? _controller.requestCount
                        : 0,
                    onTap: _openRequests,
                  ),
                  if (_controller.error case final message?)
                    Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.cloud_off_outlined),
                        title: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: TextButton(
                          onPressed: _controller.load,
                          child: Text(context.l10n.retry),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
                    child: Row(
                      children: _InboxFilter.values
                          .map(
                            (filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_filterLabel(context, filter)),
                                selected: _filter == filter,
                                onSelected: (_) =>
                                    setState(() => _filter = filter),
                                selectedColor: Theme.of(context).colorScheme.primary,
                                labelStyle: TextStyle(
                                  color: _filter == filter
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                showCheckmark: false,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (conversations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 70, 24, 0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 44,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            switch (_filter) {
                              _InboxFilter.groups =>
                                context.l10n.noGroupChats,
                              _InboxFilter.unread =>
                                context.l10n.noUnreadChats,
                              _InboxFilter.all =>
                                context.l10n.noConversations,
                            },
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...conversations.map(
                    (conversation) => _ConversationRow(
                      conversation: conversation,
                      showAttention: conversation.type == 'GROUP'
                          ? AppSettingsController
                              .instance
                              .settings
                              .notifyGroupActivity
                          : AppSettingsController
                              .instance
                              .settings
                              .notifyDirectMessages,
                      onTap: () => _openConversation(conversation),
                    ),
                  ),
                  if (_controller.conversationCursor != null &&
                      _filter == _InboxFilter.all)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: OutlinedButton(
                        onPressed: _controller.isLoadingMore ? null : _controller.loadMoreConversations,
                        child: Text(
                          _controller.isLoadingMore
                              ? context.l10n.loading
                              : context.l10n.loadMore,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const NavigationWidget(currentPage: NavigationPage.notifications),
    );
  }

  List<DirectConversationDto> _visibleConversations() {
    final inbox = _controller.conversations
        .where((item) => !(item.status == 'PENDING' && item.incomingRequest));
    return switch (_filter) {
      _InboxFilter.unread =>
        inbox.where((item) => item.unreadCount > 0).toList(),
      _InboxFilter.groups =>
        inbox.where((item) => item.type == 'GROUP').toList(),
      _ => inbox.toList(),
    };
  }
}

class _RequestBanner extends StatelessWidget {
  const _RequestBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.mark_chat_unread_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.requests,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.showAttention,
    required this.onTap,
  });
  final DirectConversationDto conversation;
  final bool showAttention;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = showAttention && conversation.unreadCount > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: ProfileAvatar(
        initials: conversation.avatarInitials,
        colorHex: conversation.avatarColor,
        imageUrl: conversation.otherUser?.avatarUrl,
        radius: 27,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(conversation.title,
                style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
          ),
          if (conversation.lastMessageAt case final date?)
            Text(
              _relative(context, date),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      subtitle: Text(
        conversation.lastMessageType == 'CERAMIC'
            ? context.l10n.ceramicMessagePreview
            : conversation.lastMessagePreview ?? context.l10n.noMessagesYet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unread
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: unread ? FontWeight.w600 : null,
        ),
      ),
      trailing: unread
          ? CircleAvatar(
              radius: 11,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text('${conversation.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
            )
          : null,
      onTap: onTap,
    );
  }

  static String _relative(BuildContext context, DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return context.l10n.now;
    if (difference.inHours < 1) {
      return context.l10n.relativeMinutes(difference.inMinutes);
    }
    if (difference.inDays < 1) {
      return context.l10n.relativeHours(difference.inHours);
    }
    if (difference.inDays < 7) {
      return context.l10n.relativeDays(difference.inDays);
    }
    return DateFormat.Md(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }
}

class _InboxRetry extends StatelessWidget {
  const _InboxRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}

String _filterLabel(BuildContext context, _InboxFilter filter) {
  return switch (filter) {
    _InboxFilter.all => context.l10n.all,
    _InboxFilter.unread => context.l10n.unread,
    _InboxFilter.groups => context.l10n.groups,
  };
}
