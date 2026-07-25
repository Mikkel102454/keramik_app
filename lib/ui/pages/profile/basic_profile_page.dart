import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page.dart';
import 'package:ceramic_app/ui/pages/notification/message_request_page.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class BlockedAccountResult {
  const BlockedAccountResult(this.userId, this.username);
  final String userId;
  final String username;
}

class BasicProfilePage extends StatefulWidget {
  const BasicProfilePage({required this.initialProfile, super.key});

  final UserProfileDto initialProfile;

  @override
  State<BasicProfilePage> createState() => _BasicProfilePageState();
}

class _BasicProfilePageState extends State<BasicProfilePage> {
  late UserProfileDto _profile = widget.initialProfile;
  bool _busy = false;

  Future<void> _perform(Future<UserProfileDto> Function() action) async {
    setState(() => _busy = true);
    try {
      final profile = await action();
      if (mounted) setState(() => _profile = profile);
    } catch (exception) {
      if (mounted) _showError(exception);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unfriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.removeFriendQuestion),
        content: Text(
          context.l10n.removeFriendExplanation(_profile.username),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await SocialRepository.unfriend(_profile.userId);
      final refreshed = await SocialRepository.getProfile(_profile.userId);
      if (mounted) setState(() => _profile = refreshed);
    } catch (exception) {
      if (mounted) _showError(exception);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.blockUserQuestion(_profile.username)),
        content: Text(context.l10n.blockExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.block),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await SocialRepository.block(_profile.userId);
      if (mounted) {
        Navigator.pop(context, BlockedAccountResult(_profile.userId, _profile.username));
      }
    } catch (exception) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(exception);
      }
    }
  }

  Future<void> _openMessage({required bool request}) async {
    setState(() => _busy = true);
    try {
      DirectConversationDto? conversation;
      if (request) {
        if (mounted) {
          conversation = await Navigator.push<DirectConversationDto>(
            context,
            MaterialPageRoute(builder: (_) => MessageRequestPage(user: _profile)),
          );
        }
      } else {
        conversation = await ChatRepository.createDirect(_profile.userId);
      }
      if (!mounted || conversation == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConversationPage(initialConversation: conversation!)),
      );
      if (!mounted) return;
      final refreshed = await SocialRepository.getProfile(_profile.userId);
      if (mounted) setState(() => _profile = refreshed);
    } catch (exception) {
      if (mounted) _showError(exception);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object exception) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ProfileAvatar(
              initials: _profile.avatarInitials,
              colorHex: _profile.avatarColor,
              imageUrl: _profile.avatarUrl,
              radius: 54,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile.username,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _relationshipLabel(context, _profile.relationshipState),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (!_busy) ...[
            if (_profile.actions.contains('SEND_FRIEND_REQUEST'))
              FilledButton.icon(
                onPressed: () => _perform(() => SocialRepository.sendFriendRequest(_profile.userId)),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(context.l10n.sendFriendRequest),
              ),
            if (_profile.actions.contains('ACCEPT_FRIEND_REQUEST'))
              FilledButton(
                onPressed: _profile.friendRequestId == null
                    ? null
                    : () => _perform(() => SocialRepository.acceptFriendRequest(_profile.friendRequestId!)),
                child: Text(context.l10n.acceptRequest),
              ),
            if (_profile.actions.contains('DECLINE_FRIEND_REQUEST'))
              OutlinedButton(
                onPressed: _profile.friendRequestId == null
                    ? null
                    : () => _perform(() => SocialRepository.declineFriendRequest(_profile.friendRequestId!)),
                child: Text(context.l10n.declineRequest),
              ),
            if (_profile.actions.contains('MESSAGE'))
              OutlinedButton.icon(
                onPressed: () => _openMessage(request: false),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(context.l10n.message),
              ),
            if (_profile.actions.contains('MESSAGE_REQUEST'))
              OutlinedButton.icon(
                onPressed: () => _openMessage(request: true),
                icon: const Icon(Icons.mark_chat_unread_outlined),
                label: Text(context.l10n.sendMessageRequest),
              ),
            if (_profile.actions.contains('UNFRIEND'))
              TextButton(
                onPressed: _unfriend,
                child: Text(context.l10n.removeFriend),
              ),
            if (_profile.actions.contains('BLOCK'))
              TextButton(
                onPressed: _block,
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: Text(context.l10n.blockAccount),
              ),
          ],
        ],
      ),
    );
  }

  static String _relationshipLabel(BuildContext context, String state) {
    return switch (state) {
      'FRIENDS' => context.l10n.relationshipFriends,
      'OUTGOING_PENDING' => context.l10n.friendRequestSent,
      'INCOMING_PENDING' => context.l10n.wantsToBeFriends,
      'DECLINED_BY_YOU' => context.l10n.previouslyDeclined,
      'DECLINED_BY_THEM' => context.l10n.friendRequestDeclined,
      _ => context.l10n.account,
    };
  }
}
