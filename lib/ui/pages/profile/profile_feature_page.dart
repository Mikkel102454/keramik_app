import 'package:clay_dock/ui/widgets/ceramic_journal_card.dart';
import 'package:clay_dock/ui/widgets/ceramic_preview_tile.dart';
import 'package:clay_dock/ui/pages/profile/friends_page.dart';
import 'package:clay_dock/ui/pages/profile/profile_edit_page.dart';
import 'package:clay_dock/ui/pages/profile/profile_page_controller.dart';
import 'package:clay_dock/ui/pages/analytics/practice_analytics_page.dart';
import 'package:clay_dock/ui/pages/settings/settings_page.dart';
import 'package:clay_dock/ui/pages/home/ceramic_view/ceramic_view_page.dart';
import 'package:clay_dock/ui/pages/profile/profile_widgets.dart';
import 'package:clay_dock/ui/widgets/v2/navigation_widget.dart';
import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';

class ProfileFeaturePage extends StatefulWidget {
  const ProfileFeaturePage({super.key, this.controller});
  final ProfilePageController? controller;

  @override
  State<ProfileFeaturePage> createState() => _ProfileFeaturePageState();
}

class _ProfileFeaturePageState extends State<ProfileFeaturePage> {
  late final ProfilePageController _controller =
      widget.controller ?? ProfilePageController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return StudioScaffold(
      currentPage: NavigationPage.profile,
      appBar: AppBar(
        title: Text(context.l10n.navigationProfile),
        actions: [
          IconButton(
            tooltip: context.l10n.settingsAndPrivacy,
            onPressed: () => _open(const SettingsPage()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StudioContent(
          maxWidth: CeramicPreviewGrid.maxWidth,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isLoading && _controller.account == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.error != null && _controller.account == null) {
                return _Retry(
                  message: context.l10n.operationFailed,
                  onRetry: _controller.load,
                );
              }
              final account = _controller.account;
              if (account == null) return const SizedBox.shrink();
              return LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    onRefresh: _controller.load,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          sliver: SliverList.list(
                            children: [
                              ProfileIdentity(
                                username: account.username,
                                initials: account.avatarInitials,
                                colorHex: account.avatarColor,
                                imageUrl: account.avatarUrl,
                                stats: [
                                  ProfileStat(
                                    value:
                                        '${_controller.friends.length}${_controller.friendsCursor == null ? '' : '+'}',
                                    label: context.l10n.relationshipFriends,
                                    onTap: () => _open(
                                      FriendsPage(controller: _controller),
                                    ),
                                  ),
                                ],
                                actions: OutlinedButton(
                                  onPressed: () => _open(
                                    ProfileEditPage(controller: _controller),
                                  ),
                                  child: Text(context.l10n.editProfile),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.insights_outlined),
                                title: Text(context.l10n.practiceAnalytics),
                                subtitle: Text(
                                  context.l10n.practiceAnalyticsPrivate,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    _open(const PracticeAnalyticsPage()),
                              ),
                              const Divider(height: 20),
                              if (_controller.finishedCeramics.isEmpty)
                                StudioEmptyState(
                                  icon: Icons.auto_awesome_outlined,
                                  title: context.l10n.finishedPiecesEmpty,
                                ),
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 16),
                          sliver: SliverGrid.builder(
                            itemCount: _controller.finishedCeramics.length,
                            gridDelegate: CeramicPreviewGrid.delegate(
                              constraints.maxWidth,
                              MediaQuery.textScalerOf(context),
                            ),
                            itemBuilder: (_, index) {
                              final ceramic =
                                  _controller.finishedCeramics[index];
                              return CeramicJournalCard(
                                key: ValueKey(ceramic.id),
                                ceramic: ceramic,
                                stageTitle: localizedStageName(
                                  context.l10n,
                                  _controller.stages
                                          .where(
                                            (stage) =>
                                                stage.id == ceramic.stageId,
                                          )
                                          .map((stage) => stage.title)
                                          .firstOrNull ??
                                      'Finished',
                                ),
                                clayTitle: _controller.clays
                                    .where(
                                      (clay) => clay.id == ceramic.clayTypeId,
                                    )
                                    .map((clay) => clay.title)
                                    .firstOrNull,
                                onTap: () => _open(
                                  CeramicViewPage(
                                    ceramic: ceramic,
                                    stages: _controller.stages,
                                    clayTypes: _controller.clays,
                                    glazes: _controller.glazes,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
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
