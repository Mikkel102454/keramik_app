import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/repositories/publication_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/pages/discover/discover_controller.dart';
import 'package:ceramic_app/ui/pages/discover/publication_detail_page.dart';
import 'package:ceramic_app/ui/pages/profile/basic_profile_page.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:ceramic_app/ui/pages/notification/ceramic_sharing_pages.dart';
import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _forYou = DiscoverController('FOR_YOU');
  final _latest = DiscoverController('LATEST');

  @override
  void initState() {
    super.initState();
    _forYou.load();
    _latest.load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _forYou.dispose();
    _latest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.navigationDiscover),
          bottom: TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: context.l10n.discoverForYou),
              Tab(text: context.l10n.discoverLatest),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [_Feed(controller: _forYou), _Feed(controller: _latest)],
        ),
        bottomNavigationBar:
            const NavigationWidget(currentPage: NavigationPage.discover),
      );
}

class _Feed extends StatelessWidget {
  const _Feed({required this.controller});
  final DiscoverController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.loading && controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null && controller.items.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: () => controller.load(refresh: true),
                child: Text(context.l10n.tryAgain),
              ),
            );
          }
          if (controller.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => controller.load(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(child: Text(context.l10n.discoverEmpty)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => controller.load(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: controller.items.length + (controller.nextCursor == null ? 0 : 1),
              itemBuilder: (context, index) {
                if (index == controller.items.length) {
                  controller.load();
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final item = controller.items[index];
                return _PublicationPost(
                  item: item,
                  onOpen: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicationDetailPage(
                        publicationId: item.publicationId,
                      ),
                    ),
                  ),
                  onOpenCreator: () =>
                      _openCreator(context, item.creator.userId),
                  onLike: item.ownedByMe
                      ? null
                      : () => controller.toggleLike(index),
                  onHide: () async {
                    final removed = await controller.hide(index);
                    if (removed != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 5),
                          content: Text(context.l10n.notInterestedAction),
                          action: SnackBarAction(
                            label: context.l10n.undoAction,
                            onPressed: () =>
                                controller.undoHide(index, removed),
                          ),
                        ),
                      );
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
      await controller.load(refresh: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.accountBlocked(blocked.username)),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () async {
              try {
                await SocialRepository.unblock(blocked.userId);
                await controller.load(refresh: true);
              } catch (exception) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(exception.toString())),
                  );
                }
              }
            },
          ),
        ),
      );
    } catch (exception) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.toString())),
        );
      }
    }
  }

  Future<void> _report(BuildContext context, String publicationId) async {
    var category = 'SPAM';
    final explanation = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.reportPublication),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  context.l10n.publicationReportEvidenceDisclosure,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: context.l10n.reportReason),
                  items: const [
                    'SPAM',
                    'HARASSMENT_OR_HATE',
                    'SEXUAL_CONTENT',
                    'VIOLENCE_OR_DANGEROUS',
                    'STOLEN_WORK_OR_IP',
                    'OTHER',
                  ].map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(
                      context.l10n.publicationReportCategory(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (value) =>
                      setState(() => category = value ?? category),
                ),
                TextFormField(
                  controller: explanation,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration:
                      InputDecoration(labelText: context.l10n.reportExplanation),
                  validator: (value) {
                    final length = value?.trim().runes.length ?? 0;
                    final required =
                        category == 'STOLEN_WORK_OR_IP' || category == 'OTHER';
                    if ((required && length < 10) ||
                        (length > 0 && length < 10) ||
                        length > 2000) {
                      return context.l10n.reportOtherExplanationRequired;
                    }
                    return null;
                  },
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(context.l10n.submitReport),
            ),
          ],
        ),
      ),
    );
    if (submit == true) {
      await PublicationRepository.report(publicationId, category, explanation.text);
    }
    explanation.dispose();
  }
}

class _PublicationPost extends StatelessWidget {
  const _PublicationPost({
    required this.item,
    required this.onOpen,
    required this.onOpenCreator,
    required this.onHide,
    required this.onReport,
    required this.onShare,
    this.onLike,
  });

  final PublicationCardDto item;
  final VoidCallback onOpen;
  final VoidCallback onOpenCreator;
  final VoidCallback? onLike;
  final VoidCallback onHide;
  final VoidCallback onReport;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    var imageFrameHeight = screenSize.width * .75;
    final screenHeightLimit = screenSize.height * .52;
    if (imageFrameHeight > screenHeightLimit) {
      imageFrameHeight = screenHeightLimit;
    }
    if (imageFrameHeight > 420) imageFrameHeight = 420;
    final published = MaterialLocalizations.of(context).formatShortDate(
      item.publishedAt.toLocal(),
    );
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 8, 9),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: item.creator.username,
                    child: InkWell(
                      onTap: onOpenCreator,
                      borderRadius: BorderRadius.circular(24),
                      child: Row(
                        children: [
                          ProfileAvatar(
                            initials: item.creator.avatarInitials,
                            colorHex: item.creator.avatarColor,
                            imageUrl: item.creator.avatarUrl,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.creator.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  published,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
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
          Semantics(
            button: true,
            label: item.title,
            child: GestureDetector(
              onTap: onOpen,
              onDoubleTap: item.likedByMe ? null : onLike,
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: SizedBox(
                  width: double.infinity,
                  height: imageFrameHeight,
                  child: item.primaryImage == null
                      ? const Center(
                          child:
                              Icon(Icons.image_not_supported_outlined, size: 46),
                        )
                      : Image.network(
                          item.primaryImage!.uri,
                          width: double.infinity,
                          height: imageFrameHeight,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            final expected = progress.expectedTotalBytes;
                            return Center(
                              child: CircularProgressIndicator(
                                value: expected == null
                                    ? null
                                    : progress.cumulativeBytesLoaded / expected,
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 46),
                          ),
                        ),
                      ),
                ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 2, 7, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.l10n.likeAction,
                  onPressed: onLike,
                  icon: Icon(
                    item.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: item.likedByMe
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.share,
                  onPressed: onShare,
                  icon: const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Text(
              '${item.likeCount} ${context.l10n.likeAction.toLowerCase()}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item.creator.username}  ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: item.title),
                ],
              ),
            ),
          ),
          if (item.clay case final clay?)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                clay,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            const SizedBox(height: 10),
          Divider(
            height: 9,
            thickness: 9,
            color: theme.colorScheme.surfaceContainerLow,
          ),
        ],
      ),
    );
  }
}
