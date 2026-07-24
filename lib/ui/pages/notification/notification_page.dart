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

@RoutePage()
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationControllerPage _controller = NotificationControllerPage();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Search accounts',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSearchPage())),
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<String>(
            onSelected: _selectMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'group', child: Text('New group')),
              PopupMenuItem(value: 'archive', child: Text('Archived chats')),
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
                  _RequestBanner(count: _controller.requestCount, onTap: _openRequests),
                  if (_controller.error case final message?)
                    Material(
                      color: const Color(0xfffff1f1),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.cloud_off_outlined),
                        title: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: TextButton(onPressed: _controller.load, child: const Text('Retry')),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
                    child: Row(
                      children: ['All', 'Unread', 'Groups']
                          .map(
                            (label) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(label),
                                selected: _filter == label,
                                onSelected: (_) => setState(() => _filter = label),
                                selectedColor: Colors.black,
                                labelStyle: TextStyle(color: _filter == label ? Colors.white : Colors.black),
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
                          const Icon(Icons.chat_bubble_outline, size: 44, color: Colors.black26),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'Groups'
                                ? 'No group chats yet.'
                                : _filter == 'Unread'
                                    ? 'No unread chats.'
                                    : 'No conversations yet. Search for an account to get started.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  ...conversations.map(
                    (conversation) => _ConversationRow(
                      conversation: conversation,
                      onTap: () => _openConversation(conversation),
                    ),
                  ),
                  if (_controller.conversationCursor != null && _filter == 'All')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: OutlinedButton(
                        onPressed: _controller.isLoadingMore ? null : _controller.loadMoreConversations,
                        child: Text(_controller.isLoadingMore ? 'Loading…' : 'Load more'),
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
      'Unread' => inbox.where((item) => item.unreadCount > 0).toList(),
      'Groups' => inbox.where((item) => item.type == 'GROUP').toList(),
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
      color: const Color(0xfff3f3f3),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.mark_chat_unread_outlined),
              const SizedBox(width: 12),
              const Expanded(child: Text('Requests', style: TextStyle(fontWeight: FontWeight.w700))),
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
  const _ConversationRow({required this.conversation, required this.onTap});
  final DirectConversationDto conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
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
            Text(_relative(date), style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
      subtitle: Text(
        conversation.lastMessagePreview ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: unread ? Colors.black87 : Colors.black45, fontWeight: unread ? FontWeight.w600 : null),
      ),
      trailing: unread
          ? CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black,
              child: Text('${conversation.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
            )
          : null,
      onTap: onTap,
    );
  }

  static String _relative(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${date.day}/${date.month}';
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
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
