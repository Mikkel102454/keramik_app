import 'package:auto_route/auto_route.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/ui/pages/notification/archived_conversations_page.dart';
import 'package:clay_dock/ui/pages/notification/chat_requests_page.dart';
import 'package:clay_dock/ui/pages/notification/conversation_page.dart';
import 'package:clay_dock/ui/pages/notification/new_group_page.dart';
import 'package:clay_dock/ui/pages/notification/notification_controller_page.dart';
import 'package:clay_dock/ui/pages/profile/user_search_page.dart';
import 'package:clay_dock/ui/widgets/profile_avatar.dart';
import 'package:clay_dock/ui/widgets/v2/navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';
import 'package:clay_dock/app/app_settings_controller.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
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
      MaterialPageRoute(
        builder: (_) => ChatRequestsPage(controller: _controller),
      ),
    );
    if (mounted) await _controller.load();
  }

  Future<void> _openConversation(DirectConversationDto conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationPage(initialConversation: conversation),
      ),
    );
    if (mounted) await _controller.load();
  }

  Future<void> _selectMenu(String value) async {
    if (value == 'archive') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ArchivedConversationsPage()),
      );
      if (mounted) await _controller.load();
    } else if (value == 'group' && mounted) {
      final group = await Navigator.push<DirectConversationDto>(
        context,
        MaterialPageRoute(builder: (_) => const NewGroupPage()),
      );
      if (!mounted || group == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationPage(initialConversation: group),
        ),
      );
      if (mounted) await _controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudioScaffold(
      currentPage: NavigationPage.notifications,
      appBar: AppBar(
        centerTitle: false,
        title: Text(context.l10n.chats),
        actions: [
          IconButton(
            tooltip: context.l10n.searchAccounts,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSearchPage()),
            ),
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<String>(
            onSelected: _selectMenu,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'group', child: Text(context.l10n.newGroup)),
              PopupMenuItem(
                value: 'archive',
                child: Text(context.l10n.archivedChats),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StudioContent(
          maxWidth: 860,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isLoading && _controller.conversations.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.error != null &&
                  _controller.conversations.isEmpty) {
                return _InboxRetry(
                  message: context.l10n.operationFailed,
                  onRetry: _controller.load,
                );
              }
              final conversations = _visibleConversations();
              return RefreshIndicator(
                onRefresh: _controller.load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      sliver: SliverList.list(
                        children: [
                          _RequestBanner(
                            count:
                                AppSettingsController
                                    .instance
                                    .settings
                                    .notifyMessageRequests
                                ? _controller.requestCount
                                : 0,
                            onTap: _openRequests,
                          ),
                          if (_controller.error != null)
                            Card(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              child: ListTile(
                                leading: const Icon(Icons.cloud_off_outlined),
                                title: Text(context.l10n.operationFailed),
                                trailing: TextButton(
                                  onPressed: _controller.load,
                                  child: Text(context.l10n.retry),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _InboxFilter.values
                                .map(
                                  (filter) => ChoiceChip(
                                    label: Text(_filterLabel(context, filter)),
                                    selected: _filter == filter,
                                    onSelected: (_) =>
                                        setState(() => _filter = filter),
                                    showCheckmark: false,
                                  ),
                                )
                                .toList(),
                          ),
                          if (conversations.isEmpty)
                            StudioEmptyState(
                              icon: Icons.chat_bubble_outline,
                              title: switch (_filter) {
                                _InboxFilter.groups =>
                                  context.l10n.noGroupChats,
                                _InboxFilter.unread =>
                                  context.l10n.noUnreadChats,
                                _InboxFilter.all =>
                                  context.l10n.noConversations,
                              },
                            ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.zero,
                      sliver: SliverList.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          return _ConversationRow(
                            key: ValueKey(conversation.id),
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
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child:
                            _controller.conversationCursor != null &&
                                _filter == _InboxFilter.all
                            ? OutlinedButton(
                                onPressed: _controller.isLoadingMore
                                    ? null
                                    : _controller.loadMoreConversations,
                                child: Text(
                                  _controller.isLoadingMore
                                      ? context.l10n.loading
                                      : context.l10n.loadMore,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<DirectConversationDto> _visibleConversations() {
    final inbox = _controller.conversations.where(
      (item) => !(item.status == 'PENDING' && item.incomingRequest),
    );
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
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.mark_chat_unread_outlined),
          title: Text(
            context.l10n.requests,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count > 0)
                Badge(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  label: Text('$count'),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.showAttention,
    required this.onTap,
    super.key,
  });
  final DirectConversationDto conversation;
  final bool showAttention;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = showAttention && conversation.unreadCount > 0;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: ProfileAvatar(
            initials: conversation.avatarInitials,
            colorHex: conversation.avatarColor,
            imageUrl: conversation.otherUser?.avatarUrl,
            radius: 24,
          ),
          title: Text(
            conversation.title,
            style: TextStyle(
              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.lastMessageType == 'CERAMIC'
                    ? context.l10n.ceramicMessagePreview
                    : conversation.lastMessagePreview ??
                          context.l10n.noMessagesYet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: unread ? FontWeight.w600 : null),
              ),
              if (conversation.lastMessageAt case final date?) ...[
                const SizedBox(height: 4),
                Text(
                  _relative(context, date),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
          trailing: unread
              ? Badge(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  label: Text('${conversation.unreadCount}'),
                )
              : null,
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 76, endIndent: 16),
      ],
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
    return StudioEmptyState(
      icon: Icons.cloud_off_outlined,
      title: message,
      action: FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
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
