import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';
import 'package:clay_dock/objects/user_profile_dto.dart';
import 'package:clay_dock/repositories/social_repository.dart';
import 'package:clay_dock/ui/pages/profile/basic_profile_page.dart';
import 'package:clay_dock/ui/pages/profile/user_search_controller.dart';
import 'package:clay_dock/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final UserSearchController _controller = UserSearchController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openProfile(UserProfileDto profile) async {
    final blocked = await Navigator.push<BlockedAccountResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BasicProfilePage(initialProfile: profile),
      ),
    );
    if (!mounted || blocked == null) return;
    _controller.removeResult(blocked.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.accountBlocked(blocked.username)),
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () async {
            try {
              await SocialRepository.unblock(blocked.userId);
              await _controller.retry();
            } catch (exception) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.operationFailed)),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.searchAccounts)),
      body: SafeArea(
        top: false,
        child: StudioContent(
          maxWidth: 820,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: TextField(
                    autofocus: true,
                    onChanged: _controller.queryChanged,
                    decoration: InputDecoration(
                      labelText: context.l10n.searchAccounts,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    if (_controller.query.runes.length < 3) {
                      return StudioEmptyState(
                        icon: Icons.search,
                        title: context.l10n.searchMinimumCharacters,
                      );
                    }
                    if (_controller.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_controller.error != null) {
                      return _RetryState(
                        message: context.l10n.operationFailed,
                        onRetry: _controller.retry,
                      );
                    }
                    if (_controller.results.isEmpty) {
                      return StudioEmptyState(
                        icon: Icons.person_search_outlined,
                        title: context.l10n.noAccountsFound,
                      );
                    }
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text(
                            context.l10n.accounts,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ..._controller.results.map(
                          (profile) => ListTile(
                            leading: ProfileAvatar(
                              initials: profile.avatarInitials,
                              colorHex: profile.avatarColor,
                              imageUrl: profile.avatarUrl,
                            ),
                            title: Text(
                              profile.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _relationship(context, profile.relationshipState),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openProfile(profile),
                          ),
                        ),
                        if (_controller.nextCursor != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: OutlinedButton(
                              onPressed: _controller.isLoadingMore
                                  ? null
                                  : _controller.loadMore,
                              child: _controller.isLoadingMore
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(context.l10n.loadMore),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relationship(BuildContext context, String state) =>
      switch (state) {
        'FRIENDS' => context.l10n.friend,
        'OUTGOING_PENDING' => context.l10n.requestSent,
        'INCOMING_PENDING' => context.l10n.incomingRequest,
        _ => context.l10n.account,
      };
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});
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
