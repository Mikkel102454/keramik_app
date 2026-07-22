import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/pages/notification/notification_controller_page.dart';
import 'package:ceramic_app/ui/pages/profile/basic_profile_page.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({required this.controller, super.key});
  final NotificationControllerPage controller;

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  Future<void> _openProfile(UserProfileDto profile) async {
    final blocked = await Navigator.push<BlockedAccountResult>(
      context,
      MaterialPageRoute(builder: (_) => BasicProfilePage(initialProfile: profile)),
    );
    if (!mounted) return;
    await widget.controller.load();
    if (!mounted || blocked == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${blocked.username} blocked'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await SocialRepository.unblock(blocked.userId);
              await widget.controller.load();
            } catch (exception) {
              if (mounted) _showError(exception);
            }
          },
        ),
      ),
    );
  }

  void _showError(Object exception) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Friend requests', style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: const TabBar(tabs: [Tab(text: 'Received'), Tab(text: 'Sent')]),
        ),
        body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => TabBarView(
            children: [
              _RequestList(
                requests: widget.controller.incoming,
                emptyMessage: 'No received requests.',
                onOpen: _openProfile,
                onRefresh: widget.controller.load,
                onAccept: (request) async {
                  try {
                    await widget.controller.accept(request.id);
                  } catch (exception) {
                    if (mounted) _showError(exception);
                  }
                },
                onDecline: (request) async {
                  try {
                    await widget.controller.decline(request.id);
                  } catch (exception) {
                    if (mounted) _showError(exception);
                  }
                },
                onLoadMore: widget.controller.incomingCursor == null
                    ? null
                    : () => widget.controller.loadMore('incoming'),
              ),
              _RequestList(
                requests: widget.controller.outgoing,
                emptyMessage: 'No sent requests.',
                onOpen: _openProfile,
                onRefresh: widget.controller.load,
                onLoadMore: widget.controller.outgoingCursor == null
                    ? null
                    : () => widget.controller.loadMore('outgoing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.emptyMessage,
    required this.onOpen,
    required this.onRefresh,
    this.onAccept,
    this.onDecline,
    this.onLoadMore,
  });

  final List<FriendRequestDto> requests;
  final String emptyMessage;
  final ValueChanged<UserProfileDto> onOpen;
  final Future<void> Function() onRefresh;
  final ValueChanged<FriendRequestDto>? onAccept;
  final ValueChanged<FriendRequestDto>? onDecline;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.black54)));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          ...requests.map(
            (request) => ListTile(
              leading: ProfileAvatar(
                initials: request.user.avatarInitials,
                colorHex: request.user.avatarColor,
                imageUrl: request.user.avatarUrl,
              ),
              title: Text(request.user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(onAccept == null ? 'Request sent' : 'Wants to be friends'),
              onTap: () => onOpen(request.user),
              trailing: onAccept == null
                  ? const Icon(Icons.chevron_right)
                  : Wrap(
                      spacing: 3,
                      children: [
                        IconButton(tooltip: 'Decline', onPressed: () => onDecline?.call(request), icon: const Icon(Icons.close)),
                        IconButton(tooltip: 'Accept', onPressed: () => onAccept?.call(request), icon: const Icon(Icons.check)),
                      ],
                    ),
            ),
          ),
          if (onLoadMore != null) OutlinedButton(onPressed: onLoadMore, child: const Text('Load more')),
        ],
      ),
    );
  }
}
