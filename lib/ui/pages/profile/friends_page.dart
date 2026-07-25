import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/pages/profile/basic_profile_page.dart';
import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({required this.controller, super.key});
  final ProfilePageController controller;

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  String _filter = '';

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
        content: Text(context.l10n.accountBlocked(blocked.username)),
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () async {
            try {
              await SocialRepository.unblock(blocked.userId);
              await widget.controller.load();
            } catch (exception) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.toString())));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          context.l10n.relationshipFriends,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final visible = widget.controller.friends
              .where((friend) => friend.username.toLowerCase().contains(_filter.toLowerCase()))
              .toList();
          return RefreshIndicator(
            onRefresh: widget.controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  onChanged: (value) => setState(() => _filter = value.trim()),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchFriends,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 70),
                    child: Text(
                      context.l10n.noFriendsFound,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ...visible.map(
                  (friend) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: ProfileAvatar(
                      initials: friend.avatarInitials,
                      colorHex: friend.avatarColor,
                      imageUrl: friend.avatarUrl,
                    ),
                    title: Text(friend.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openProfile(friend),
                  ),
                ),
                if (widget.controller.friendsCursor != null && _filter.isEmpty)
                  OutlinedButton(
                    onPressed: widget.controller.loadMoreFriends,
                    child: Text(context.l10n.loadMore),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
