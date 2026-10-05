import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/objects/publication_dto.dart';
import 'package:clay_dock/repositories/publication_repository.dart';
import 'package:clay_dock/repositories/social_repository.dart';
import 'package:clay_dock/ui/pages/discover/discover_controller.dart';
import 'package:clay_dock/ui/pages/discover/publication_detail_page.dart';
import 'package:clay_dock/ui/pages/discover/publication_report_dialog.dart';
import 'package:clay_dock/ui/pages/profile/basic_profile_page.dart';
import 'package:clay_dock/ui/widgets/profile_avatar.dart';
import 'package:clay_dock/ui/widgets/v2/navigation_widget.dart';
import 'package:clay_dock/ui/pages/notification/ceramic_sharing_pages.dart';
import 'package:flutter/material.dart';
import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({this.forYouController, this.latestController, super.key});

  final DiscoverController? forYouController;
  final DiscoverController? latestController;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late final _forYou = widget.forYouController ?? DiscoverController('FOR_YOU');
  late final _latest = widget.latestController ?? DiscoverController('LATEST');

  @override
  void initState() {
    super.initState();
    _forYou.load();
    _latest.load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    if (widget.forYouController == null) _forYou.dispose();
    if (widget.latestController == null) _latest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StudioScaffold(
    currentPage: NavigationPage.discover,
    appBar: AppBar(
      toolbarHeight: 48,
      title: SizedBox(
        width: 280,
        child: TabBar(
          controller: _tabs,
          dividerHeight: 0,
          tabs: [
            Tab(text: context.l10n.discoverForYou),
            Tab(text: context.l10n.discoverLatest),
          ],
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: StudioContent(
        maxWidth: 900,
        child: TabBarView(
          controller: _tabs,
          children: [
            _Feed(controller: _forYou),
            _Feed(controller: _latest),
          ],
        ),
      ),
    ),
  );
}

class _Feed extends StatefulWidget {
  const _Feed({required this.controller});
  final DiscoverController controller;

  @override
  State<_Feed> createState() => _FeedState();
}

class _FeedState extends State<_Feed> with AutomaticKeepAliveClientMixin {
  bool _refreshFailed = false;
  final _pages = PageController();
  int _pageIndex = 0;
  String? _visibleId;
  DiscoverController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_reconcilePage);
  }

  @override
  void dispose() {
    controller.removeListener(_reconcilePage);
    _pages.dispose();
    super.dispose();
  }

  // Keep the same publication in view after like, hide/undo and data refresh.
  void _reconcilePage() {
    if (_visibleId == null &&
        controller.items.isNotEmpty &&
        _pageIndex == controller.items.length &&
        controller.nextCursor != null) {
      return;
    }
    final found = controller.items.indexWhere(
      (item) => item.publicationId == _visibleId,
    );
    final last = controller.items.length - 1;
    final target = found >= 0
        ? found
        : (last < 0 ? 0 : _pageIndex.clamp(0, last));
    _visibleId = controller.items.isEmpty
        ? null
        : controller.items[target].publicationId;
    if (_pageIndex == target) return;
    _pageIndex = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _pages.hasClients &&
          (_pages.page ?? 0).round() != target) {
        _pages.jumpToPage(target);
      }
    });
  }

  void _pageChanged(int index) {
    _pageIndex = index;
    if (index < controller.items.length) {
      _visibleId = controller.items[index].publicationId;
    } else if (!controller.loading &&
        controller.error == null &&
        controller.nextCursor != null) {
      _visibleId = null;
      controller.load();
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    if (controller.loading) return;
    setState(() => _refreshFailed = false);
    final loaded = await controller.load(refresh: true);
    if (mounted) {
      setState(() => _refreshFailed = !loaded && controller.error != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading && controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error != null && controller.items.isEmpty) {
          return StudioEmptyState(
            icon: Icons.cloud_off_outlined,
            title: context.l10n.ceramicsLoadFailed,
            action: FilledButton(
              onPressed: _refresh,
              child: Text(context.l10n.tryAgain),
            ),
          );
        }
        if (controller.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                StudioEmptyState(
                  icon: Icons.explore_outlined,
                  title: context.l10n.discoverEmpty,
                ),
              ],
            ),
          );
        }
        final showRefreshError = _refreshFailed && controller.error != null;
        final showNextPage = controller.nextCursor != null && !showRefreshError;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: PageView.builder(
            key: ValueKey('discover-feed-${controller.mode}'),
            controller: _pages,
            scrollDirection: Axis.vertical,
            onPageChanged: _pageChanged,
            findChildIndexCallback: (key) {
              if (key is! ValueKey<String>) return null;
              final index = controller.items.indexWhere(
                (item) => item.publicationId == key.value,
              );
              return index < 0 ? null : index;
            },
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.items.length + (showNextPage ? 1 : 0),
            itemBuilder: (context, listIndex) {
              final index = listIndex;
              if (index == controller.items.length) {
                if (controller.error != null) {
                  return StudioEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: context.l10n.ceramicsLoadFailed,
                    action: FilledButton(
                      onPressed: () => controller.load(),
                      child: Text(context.l10n.retry),
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final item = controller.items[index];
              return _PublicationPost(
                key: ValueKey(item.publicationId),
                item: item,
                refreshError: showRefreshError,
                onRefresh: _refresh,
                onOpen: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailPage(
                      publicationId: item.publicationId,
                    ),
                  ),
                ),
                onOpenCreator: () => _openCreator(context, item.creator.userId),
                onLike: item.ownedByMe
                    ? null
                    : () => controller.toggleLike(index),
                onHide: () async {
                  try {
                    final removed = await controller.hide(index);
                    if (removed != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 5),
                          content: Text(context.l10n.notInterestedAction),
                          action: SnackBarAction(
                            label: context.l10n.undoAction,
                            onPressed: () async {
                              try {
                                await controller.undoHide(index, removed);
                              } catch (_) {
                                if (context.mounted) {
                                  _showOperationError(context);
                                }
                              }
                            },
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) _showOperationError(context);
                  }
                },
                onReport: () => _report(context, item.publicationId),
                onShare: () => Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ShareCeramicConversationPickerPage.publication(
                          publicationId: item.publicationId,
                        ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openCreator(BuildContext context, String userId) async {
    try {
      final profile = await SocialRepository.getProfile(userId);
      if (!context.mounted) return;
      final blocked = await Navigator.push<BlockedAccountResult>(
        context,
        MaterialPageRoute(
          builder: (_) => BasicProfilePage(initialProfile: profile),
        ),
      );
      if (!context.mounted || blocked == null) return;
      await _refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.accountBlocked(blocked.username)),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () async {
              try {
                await SocialRepository.unblock(blocked.userId);
                await _refresh();
              } catch (exception) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.operationFailed)),
                  );
                }
              }
            },
          ),
        ),
      );
    } catch (exception) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.operationFailed)));
      }
    }
  }

  void _showOperationError(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.operationFailed)));
  }

  Future<void> _report(BuildContext context, String publicationId) async {
    final draft = await showPublicationReportDialog(context);
    if (draft == null) return;
    try {
      await PublicationRepository.report(
        publicationId,
        draft.category,
        draft.explanation,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.reportSubmitted)));
      }
    } catch (_) {
      if (context.mounted) _showOperationError(context);
    }
  }
}

/// A photo fills the viewport; real publication actions stay in a side rail.
class _PublicationPost extends StatelessWidget {
  const _PublicationPost({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onOpenCreator,
    required this.onHide,
    required this.onReport,
    required this.onShare,
    required this.onRefresh,
    this.refreshError = false,
    this.onLike,
  });

  final PublicationCardDto item;
  final VoidCallback onOpen, onOpenCreator, onHide, onReport, onShare;
  final Future<void> Function() onRefresh;
  final bool refreshError;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final published = MaterialLocalizations.of(
      context,
    ).formatShortDate(item.publishedAt.toLocal());
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 430;
        final captionHeight = constraints.maxHeight * (compact ? .6 : .38);
        return Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              button: true,
              label: item.title,
              child: InkWell(
                onTap: onOpen,
                onDoubleTap: item.likedByMe ? null : onLike,
                child: ColoredBox(
                  color: colors.surface,
                  child: item.primaryImage == null
                      ? Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 56,
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      : Image.network(
                          item.primaryImage!.uri,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes == null
                                        ? null
                                        : progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!,
                                  ),
                                ),
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 48),
                          ),
                        ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.surface.withValues(alpha: 0),
                      colors.surface.withValues(alpha: .96),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 90,
              bottom: 16,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: captionHeight),
                child: SingleChildScrollView(
                  child: StudioMediaOverlay(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onOpenCreator,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              item.creator.username,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          item.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.clay case final clay?) ...[
                          const SizedBox(height: 6),
                          Text(
                            clay,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          published,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 12,
              bottom: 12,
              child: SizedBox(
                width: 64,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    child: StudioMediaOverlay(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: item.creator.username,
                            onPressed: onOpenCreator,
                            constraints: const BoxConstraints(
                              minWidth: 56,
                              minHeight: 56,
                            ),
                            padding: EdgeInsets.zero,
                            icon: ExcludeSemantics(
                              child: ProfileAvatar(
                                initials: item.creator.avatarInitials,
                                colorHex: item.creator.avatarColor,
                                imageUrl: item.creator.avatarUrl,
                                radius: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            tooltip: context.l10n.likeAction,
                            onPressed: onLike,
                            iconSize: 34,
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: Icon(
                              item.likedByMe
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: item.likedByMe
                                  ? colors.primary
                                  : colors.onSurface,
                            ),
                          ),
                          Text(
                            '${item.likeCount}',
                            style: theme.textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            tooltip: context.l10n.share,
                            onPressed: onShare,
                            iconSize: 30,
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: const Icon(
                              Icons.reply_rounded,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            tooltip: context.l10n.information,
                            onPressed: onOpen,
                            iconSize: 28,
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: const Icon(Icons.info_outline_rounded),
                          ),
                          const SizedBox(height: 8),
                          PopupMenuButton<String>(
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).moreButtonTooltip,
                            icon: const Icon(Icons.more_horiz),
                            onSelected: (value) {
                              if (value == 'hide') {
                                onHide();
                              } else if (value == 'report') {
                                onReport();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'hide',
                                child: Text(context.l10n.notInterestedAction),
                              ),
                              PopupMenuItem(
                                value: 'report',
                                child: Text(context.l10n.reportPublication),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (refreshError)
              Positioned(
                left: 12,
                right: 12,
                top: 8,
                child: Material(
                  color: colors.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(context.l10n.ceramicsLoadFailed),
                        TextButton(
                          onPressed: onRefresh,
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
