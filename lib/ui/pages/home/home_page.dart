import 'package:clay_dock/ui/widgets/ceramic_preview_tile.dart';
import 'package:clay_dock/ui/widgets/feature_gate.dart';
import 'package:clay_dock/objects/entitlement_dto.dart';
import 'package:auto_route/auto_route.dart';
import 'package:clay_dock/objects/ceramic_dto.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/repositories/ceramic_batch_repository.dart';
import 'package:clay_dock/ui/pages/home/ceramic_create/ceramic_create_page.dart';
import 'package:clay_dock/ui/pages/home/ceramic_view/ceramic_view_page.dart';
import 'package:clay_dock/ui/pages/home/ceramic_journal_query.dart';
import 'package:clay_dock/ui/pages/home/batch/ceramic_batch_delete_review_dialog.dart';
import 'package:clay_dock/ui/pages/home/batch/ceramic_batch_edit_page.dart';
import 'package:clay_dock/ui/pages/home/templates/project_templates_page.dart';
import 'package:clay_dock/ui/widgets/ceramic_journal_card.dart';
import 'package:clay_dock/ui/widgets/v2/navigation_widget.dart';
import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'home_page_controller.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final HomePageController _controller = HomePageController();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  bool _selectionMode = false;
  bool _selectionBusy = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return StudioScaffold(
      currentPage: NavigationPage.home,
      appBar: AppBar(
        title: Text(
          _selectionMode
              ? context.l10n.selectedCeramics(_selectedIds.length)
              : context.l10n.ceramicJournal,
        ),
        leading: _selectionMode
            ? IconButton(
                tooltip: context.l10n.cancel,
                onPressed: _exitSelection,
                icon: const Icon(Icons.close),
              )
            : null,
        actions: [
          if (!_selectionMode)
            IconButton(
              tooltip: context.l10n.projectTemplates,
              onPressed: _openTemplates,
              icon: const Icon(Icons.content_copy_outlined),
            ),
          IconButton(
            tooltip: _selectionMode
                ? context.l10n.selectAllVisible
                : context.l10n.selectCeramics,
            onPressed: _selectionMode ? _selectAllVisible : _enterSelection,
            icon: Icon(
              _selectionMode ? Icons.select_all : Icons.checklist_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading && _controller.ceramics.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.error != null && _controller.ceramics.isEmpty) {
              return StudioEmptyState(
                icon: Icons.cloud_off_outlined,
                title: context.l10n.journalLoadFailed,
                action: FilledButton.icon(
                  onPressed: _controller.load,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.tryAgain),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _controller.load,
              child: _pageContent(_controller),
            );
          },
        ),
      ),
      floatingActionButtonLocation: _selectionMode
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => !_selectionMode && _controller.ceramics.isEmpty
            ? const SizedBox.shrink()
            : _selectionMode
            ? _SelectionActions(
                busy: _selectionBusy,
                enabled: _selectedIds.isNotEmpty,
                onDelete: _batchDelete,
                onEdit: _batchEdit,
              )
            : FloatingActionButton(
                onPressed: _createCeramic,
                tooltip: context.l10n.createCeramic,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Widget _pageContent(HomePageController controller) {
    final ceramics = controller.visibleCeramics;
    return StudioContent(
      maxWidth: CeramicPreviewGrid.maxWidth,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (controller.ceramics.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.isLoading) const LinearProgressIndicator(),
                    if (controller.error != null) ...[
                      Text(
                        context.l10n.journalLoadFailed,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: controller.load,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.retry),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => controller.updateQuery(
                              controller.query.copyWith(search: value),
                            ),
                            decoration: InputDecoration(
                              hintText: context.l10n.journalSearchHint,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: controller.query.search.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: context.l10n.clearSearch,
                                      onPressed: () {
                                        _searchController.clear();
                                        controller.updateQuery(
                                          controller.query.copyWith(search: ''),
                                        );
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Badge(
                          isLabelVisible:
                              controller.query.activeFilterCount > 0,
                          label: Text('${controller.query.activeFilterCount}'),
                          child: IconButton(
                            tooltip: context.l10n.filters,
                            onPressed: _showFilters,
                            icon: const Icon(Icons.tune),
                          ),
                        ),
                      ],
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: (constraints.maxWidth - 60)
                                .clamp(100, 220)
                                .toDouble(),
                            child: PopupMenuButton<CeramicJournalSort>(
                              tooltip: _sortLabel(
                                context,
                                controller.query.sort,
                              ),
                              onSelected: (sort) => controller.updateQuery(
                                controller.query.copyWith(
                                  sort: sort,
                                  descending: switch (sort) {
                                    CeramicJournalSort.title ||
                                    CeramicJournalSort.stage => false,
                                    _ => true,
                                  },
                                ),
                              ),
                              itemBuilder: (_) => CeramicJournalSort.values
                                  .map(
                                    (sort) => PopupMenuItem(
                                      value: sort,
                                      child: Text(_sortLabel(context, sort)),
                                    ),
                                  )
                                  .toList(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sort, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _sortLabel(
                                          context,
                                          controller.query.sort,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: controller.query.descending
                                ? context.l10n.descending
                                : context.l10n.ascending,
                            onPressed: () => controller.updateQuery(
                              controller.query.copyWith(
                                descending: !controller.query.descending,
                              ),
                            ),
                            icon: Icon(
                              controller.query.descending
                                  ? Icons.south
                                  : Icons.north,
                              size: 18,
                            ),
                          ),
                          Text(
                            context.l10n.pieceCount(ceramics.length),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (controller.ceramics.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyJournal(onCreate: _createCeramic),
            )
          else if (ceramics.isEmpty)
            SliverToBoxAdapter(
              child: _NoMatches(
                onClear: () {
                  _searchController.clear();
                  controller.updateQuery(
                    controller.query.clearFilters().copyWith(search: ''),
                  );
                },
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                return SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverGrid.builder(
                    itemCount: ceramics.length,
                    gridDelegate: CeramicPreviewGrid.delegate(
                      constraints.crossAxisExtent,
                      MediaQuery.textScalerOf(context),
                    ),
                    itemBuilder: (_, index) {
                      final ceramic = ceramics[index];
                      final selected = _selectedIds.contains(ceramic.id);
                      return Stack(
                        key: ValueKey(ceramic.id),
                        children: [
                          Positioned.fill(
                            child: CeramicJournalCard(
                              ceramic: ceramic,
                              stageTitle:
                                  controller.stages
                                      .where(
                                        (stage) => stage.id == ceramic.stageId,
                                      )
                                      .map((stage) => stage.title)
                                      .map(
                                        (title) => localizedStageName(
                                          context.l10n,
                                          title,
                                        ),
                                      )
                                      .firstOrNull ??
                                  context.l10n.unknownStage,
                              clayTitle: controller.clays
                                  .where(
                                    (clay) => clay.id == ceramic.clayTypeId,
                                  )
                                  .map((clay) => clay.title)
                                  .firstOrNull,
                              onTap: () => _selectionMode
                                  ? _toggleSelection(ceramic.id)
                                  : _openCeramic(ceramic),
                            ),
                          ),
                          if (_selectionMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IgnorePointer(
                                child: CircleAvatar(
                                  backgroundColor: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surface,
                                  child: Icon(
                                    selected
                                        ? Icons.check
                                        : Icons.circle_outlined,
                                    color: selected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          if (controller.ceramics.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
        ],
      ),
    );
  }

  Future<void> _createCeramic() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(context.l10n.createBlankCeramic),
              onTap: () => Navigator.pop(sheetContext, 'blank'),
            ),
            ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: Text(context.l10n.createFromTemplate),
              onTap: () => Navigator.pop(sheetContext, 'template'),
            ),
          ],
        ),
      ),
    );
    if (action == 'template' && mounted) {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const ProjectTemplatesPage(pickForCreation: true),
        ),
      );
      if (changed == true && mounted) await _controller.load();
      return;
    }
    if (action != 'blank') {
      return;
    }
    await _createBlankCeramic();
  }

  Future<void> _createBlankCeramic() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CeramicCreatePage(
          stages: _controller.stages,
          clayTypes: _controller.clays,
          glazes: _controller.glazes,
        ),
      ),
    );
    if (result == true && mounted) await _controller.load();
  }

  Future<void> _openTemplates() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProjectTemplatesPage()),
    );
    if (changed == true && mounted) await _controller.load();
  }

  void _enterSelection() => setState(() {
    _selectionMode = true;
    _selectedIds.clear();
  });

  void _exitSelection() => setState(() {
    _selectionMode = false;
    _selectedIds.clear();
  });

  void _toggleSelection(int id) => setState(() {
    if (!_selectedIds.add(id)) _selectedIds.remove(id);
  });

  void _selectAllVisible() => setState(() {
    final visible = _controller.visibleCeramics
        .map((value) => value.id)
        .toSet();
    if (_selectedIds.containsAll(visible)) {
      _selectedIds.removeAll(visible);
    } else {
      _selectedIds.addAll(visible.take(50));
    }
  });

  Future<void> _batchEdit() async {
    if (!await requireFeature(context, Features.batchEditing) || !mounted) {
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CeramicBatchEditPage(
          ceramicIds: _selectedIds.toList()..sort(),
          stages: _controller.stages,
          clays: _controller.clays,
        ),
      ),
    );
    if (changed == true && mounted) {
      _exitSelection();
      await _controller.load();
    }
  }

  Future<void> _batchDelete() async {
    setState(() => _selectionBusy = true);
    try {
      final preview = await CeramicBatchRepository.previewDelete(
        _selectedIds.toList()..sort(),
      );
      if (!mounted) {
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CeramicBatchDeleteReviewDialog(preview: preview),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      final result = await CeramicBatchRepository.applyDelete(preview);
      if (!mounted) {
        return;
      }
      _exitSelection();
      await _controller.load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.batchDeleteComplete(result.deletedCount)),
        ),
      );
    } catch (value) {
      if (!mounted) {
        return;
      }
      final retry = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.batchDeleteFailed),
          content: Text(
            context.l10n.requestFailure(
              value,
              context.l10n.batchDeleteFailedBody,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.tryAgain),
            ),
          ],
        ),
      );
      if (retry == true && mounted) {
        setState(() => _selectionBusy = false);
        await _batchDelete();
      }
    } finally {
      if (mounted) setState(() => _selectionBusy = false);
    }
  }

  Future<void> _openCeramic(CeramicDto ceramic) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CeramicViewPage(
          ceramic: ceramic,
          stages: _controller.stages,
          clayTypes: _controller.clays,
          glazes: _controller.glazes,
        ),
      ),
    );
    if (mounted) await _controller.load();
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = _controller.query;
          void update(CeramicJournalQuery next) {
            _controller.updateQuery(next);
            setSheetState(() {});
          }

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .78,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.filterJournal,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => update(query.clearFilters()),
                        child: Text(context.l10n.clear),
                      ),
                    ],
                  ),
                  _FilterSection(
                    title: context.l10n.stage,
                    children: _controller.stages
                        .map(
                          (stage) => FilterChip(
                            label: Text(
                              localizedStageName(context.l10n, stage.title),
                            ),
                            selected: query.stageIds.contains(stage.id),
                            onSelected: (_) => update(
                              query.copyWith(
                                stageIds: _toggle(query.stageIds, stage.id),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  _FilterSection(
                    title: context.l10n.clay,
                    children: _controller.clays
                        .map(
                          (clay) => FilterChip(
                            label: Text(clay.title),
                            selected: query.clayIds.contains(clay.id),
                            onSelected: (_) => update(
                              query.copyWith(
                                clayIds: _toggle(query.clayIds, clay.id),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  _FilterSection(
                    title: context.l10n.glaze,
                    children: _controller.glazes
                        .map(
                          (glaze) => FilterChip(
                            label: Text(glaze.title),
                            selected: query.glazeIds.contains(glaze.id),
                            onSelected: (_) => update(
                              query.copyWith(
                                glazeIds: _toggle(query.glazeIds, glaze.id),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  _FilterSection(
                    title: context.l10n.minimumRating,
                    children: List.generate(
                      5,
                      (index) => ChoiceChip(
                        label: Text('${index + 1}+ ★'),
                        selected: query.minimumRating == index + 1,
                        onSelected: (selected) => update(
                          query.copyWith(
                            minimumRating: selected ? index + 1 : 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_controller.availableTags.isNotEmpty)
                    _FilterSection(
                      title: context.l10n.tags,
                      children: _controller.availableTags.map((tag) {
                        final normalized = tag.toLowerCase();
                        return FilterChip(
                          label: Text(tag),
                          selected: query.tags.contains(normalized),
                          onSelected: (_) => update(
                            query.copyWith(
                              tags: _toggle(query.tags, normalized),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Set<T> _toggle<T>(Set<T> values, T value) {
    final result = Set<T>.from(values);
    result.contains(value) ? result.remove(value) : result.add(value);
    return result;
  }

  static String _sortLabel(BuildContext context, CeramicJournalSort sort) =>
      switch (sort) {
        CeramicJournalSort.recentlyViewed => context.l10n.sortRecentlyViewed,
        CeramicJournalSort.recentlyUpdated => context.l10n.sortRecentlyUpdated,
        CeramicJournalSort.title => context.l10n.title,
        CeramicJournalSort.rating => context.l10n.rating,
        CeramicJournalSort.stage => context.l10n.stage,
        CeramicJournalSort.created => context.l10n.creationDate,
      };
}

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({
    required this.busy,
    required this.enabled,
    required this.onDelete,
    required this.onEdit,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(StudioSpacing.radius),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled && !busy ? onDelete : null,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(context.l10n.delete),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: enabled && !busy ? onEdit : null,
                  icon: const Icon(Icons.edit_note),
                  label: Text(context.l10n.batchEdit),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    ),
  );
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => StudioEmptyState(
    scrollable: false,
    icon: Icons.handyman_outlined,
    title: context.l10n.startCeramicJournal,
    message: context.l10n.emptyJournalDescription,
    action: FilledButton.icon(
      onPressed: onCreate,
      icon: const Icon(Icons.add),
      label: Text(context.l10n.createFirstPiece),
    ),
  );
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => StudioEmptyState(
    icon: Icons.search_off,
    title: context.l10n.noMatchingPieces,
    action: OutlinedButton(
      onPressed: onClear,
      child: Text(context.l10n.clearSearchAndFilters),
    ),
  );
}
