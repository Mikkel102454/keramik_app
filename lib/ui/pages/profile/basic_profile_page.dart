import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/public_ceramic_card_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page.dart';
import 'package:ceramic_app/ui/pages/notification/message_request_page.dart';
import 'package:ceramic_app/ui/widgets/ceramic_journal_card.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class BlockedAccountResult {
  const BlockedAccountResult(this.userId, this.username);
  final String userId;
  final String username;
}

typedef LoadFinishedCeramics =
    Future<List<PublicCeramicCardDto>> Function(String userId);

class BasicProfilePage extends StatefulWidget {
  const BasicProfilePage({
    required this.initialProfile,
    this.loadFinishedCeramics,
    super.key,
  });

  final UserProfileDto initialProfile;
  final LoadFinishedCeramics? loadFinishedCeramics;

  @override
  State<BasicProfilePage> createState() => _BasicProfilePageState();
}

class _BasicProfilePageState extends State<BasicProfilePage> {
  late UserProfileDto _profile = widget.initialProfile;
  List<PublicCeramicCardDto> _finishedCeramics = const [];
  bool _busy = false;
  bool _loadingCeramics = true;
  Object? _ceramicsError;

  @override
  void initState() {
    super.initState();
    _loadFinishedCeramics();
  }

  Future<void> _loadFinishedCeramics() async {
    setState(() {
      _loadingCeramics = true;
      _ceramicsError = null;
    });
    try {
      final loader =
          widget.loadFinishedCeramics ?? SocialRepository.getFinishedCeramics;
      final ceramics = await loader(_profile.userId);
      if (mounted) setState(() => _finishedCeramics = ceramics);
    } catch (exception) {
      if (mounted) setState(() => _ceramicsError = exception);
    } finally {
      if (mounted) setState(() => _loadingCeramics = false);
    }
  }

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
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Center(
            child: ProfileAvatar(
              initials: _profile.avatarInitials,
              colorHex: _profile.avatarColor,
              imageUrl: _profile.avatarUrl,
              radius: 42,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _profile.username,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _relationshipLabel(context, _profile.relationshipState),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 18),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 10),
            child: Row(
              children: [
                Text(
                  context.l10n.finishedPieces,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text('${_finishedCeramics.length}'),
              ],
            ),
          ),
          if (_loadingCeramics)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_ceramicsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: OutlinedButton(
                  onPressed: _loadFinishedCeramics,
                  child: Text(context.l10n.retry),
                ),
              ),
            )
          else if (_finishedCeramics.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 46),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.finishedPiecesEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _finishedCeramics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .72,
              ),
              itemBuilder: (context, index) {
                final ceramic = _finishedCeramics[index];
                return CeramicJournalCard.public(
                  publicTitle: ceramic.title,
                  publicRating: ceramic.rating,
                  publicImageUrl: ceramic.imageUrl,
                  stageTitle: localizedStageName(
                    context.l10n,
                    ceramic.stage,
                  ),
                  clayTitle: ceramic.clayTitle,
                );
              },
            ),
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
