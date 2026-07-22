import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page.dart';
import 'package:ceramic_app/ui/pages/notification/friend_requests_page.dart';
import 'package:ceramic_app/ui/pages/notification/notification_controller_page.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class ChatRequestsPage extends StatelessWidget {
  const ChatRequestsPage({required this.controller, super.key});
  final NotificationControllerPage controller;

  void _showError(BuildContext context, Object exception) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$exception')));
  }

  Future<void> _accept(BuildContext context, DirectConversationDto item) async {
    try {
      final active = await controller.acceptMessageRequest(item.id);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConversationPage(initialConversation: active)),
      );
      await controller.load();
    } catch (exception) {
      if (context.mounted) _showError(context, exception);
    }
  }

  Future<void> _decline(BuildContext context, DirectConversationDto item) async {
    try {
      await controller.declineMessageRequest(item.id);
    } catch (exception) {
      if (context.mounted) _showError(context, exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requests', style: TextStyle(fontWeight: FontWeight.w700))),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final requests = controller.incomingMessageRequests;
          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
                  title: const Text('Friend requests', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${controller.incoming.length} waiting'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FriendRequestsPage(controller: controller)),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('Message requests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('No message requests.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45)),
                  ),
                ...requests.map(
                  (item) => ListTile(
                    leading: ProfileAvatar(
                      initials: item.otherUser!.avatarInitials,
                      colorHex: item.otherUser!.avatarColor,
                      imageUrl: item.otherUser!.avatarUrl,
                    ),
                    title: Text(item.otherUser!.username, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(item.lastMessagePreview ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(tooltip: 'Decline', onPressed: () => _decline(context, item), icon: const Icon(Icons.close)),
                        IconButton(tooltip: 'Accept', onPressed: () => _accept(context, item), icon: const Icon(Icons.check)),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ConversationPage(initialConversation: item)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
