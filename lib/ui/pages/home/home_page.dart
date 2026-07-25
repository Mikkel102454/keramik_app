import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_create/ceramic_create_page.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_view/ceramic_view_page.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_journal_query.dart';
import 'package:ceramic_app/ui/widgets/ceramic_journal_card.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'home_page_controller.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver {
  final HomePageController _controller = HomePageController();
  final TextEditingController _searchController = TextEditingController();

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ceramicJournal)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading && _controller.ceramics.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.journalLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _controller.load,
                      child: Text(context.l10n.tryAgain),
                    ),
                  ]),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _createCeramic,
        tooltip: context.l10n.createCeramic,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const NavigationWidget(currentPage: NavigationPage.home),
    );
  }

  Widget _pageContent(HomePageController controller) {
    final ceramics = controller.visibleCeramics;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => controller.updateQuery(controller.query.copyWith(search: value)),
          decoration: InputDecoration(
            hintText: context.l10n.journalSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.query.search.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.clearSearch,
                    onPressed: () {
                      _searchController.clear();
                      controller.updateQuery(controller.query.copyWith(search: ''));
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Badge(
              isLabelVisible: controller.query.activeFilterCount > 0,
              label: Text('${controller.query.activeFilterCount}'),
              child: OutlinedButton.icon(
                onPressed: _showFilters,
                icon: const Icon(Icons.tune),
                label: Text(context.l10n.filters),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PopupMenuButton<CeramicJournalSort>(
                onSelected: (sort) => controller.updateQuery(
                  controller.query.copyWith(
                    sort: sort,
                    descending: switch (sort) {
                      CeramicJournalSort.title || CeramicJournalSort.stage => false,
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
                child: InputDecorator(
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sort),
                  ),
                  child: Text(_sortLabel(context, controller.query.sort)),
                ),
              ),
            ),
            IconButton(
              tooltip: controller.query.descending
                  ? context.l10n.descending
                  : context.l10n.ascending,
              onPressed: () => controller.updateQuery(
                controller.query.copyWith(descending: !controller.query.descending),
              ),
              icon: Icon(controller.query.descending ? Icons.south : Icons.north),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.pieceCount(ceramics.length),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 10),
        if (controller.ceramics.isEmpty)
          _EmptyJournal(onCreate: _createCeramic)
        else if (ceramics.isEmpty)
          _NoMatches(
            onClear: () {
              _searchController.clear();
              controller.updateQuery(
                controller.query.clearFilters().copyWith(search: ''),
              );
            },
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ceramics.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: .72,
                ),
                itemBuilder: (_, index) {
                  final ceramic = ceramics[index];
                  return CeramicJournalCard(
                    ceramic: ceramic,
                    stageTitle: controller.stages
                        .where((stage) => stage.id == ceramic.stageId)
                        .map((stage) => stage.title)
                        .map(
                          (title) =>
                              localizedStageName(context.l10n, title),
                        )
                        .firstOrNull ?? context.l10n.unknownStage,
                    clayTitle: controller.clays
                        .where((clay) => clay.id == ceramic.clayTypeId)
                        .map((clay) => clay.title)
                        .firstOrNull,
                    onTap: () => _openCeramic(ceramic),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _createCeramic() async {
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

  Future<void> _openCeramic(CeramicDto ceramic) async {
    final result = await Navigator.push<bool>(
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
    if (result == true && mounted) await _controller.load();
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
                  Row(children: [
                    Text(
                      context.l10n.filterJournal,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => update(query.clearFilters()),
                      child: Text(context.l10n.clear),
                    ),
                  ]),
                  _FilterSection(
                    title: context.l10n.stage,
                    children: _controller.stages.map((stage) => FilterChip(
                      label: Text(
                        localizedStageName(context.l10n, stage.title),
                      ),
                      selected: query.stageIds.contains(stage.id),
                      onSelected: (_) => update(query.copyWith(
                        stageIds: _toggle(query.stageIds, stage.id),
                      )),
                    )).toList(),
                  ),
                  _FilterSection(
                    title: context.l10n.clay,
                    children: _controller.clays.map((clay) => FilterChip(
                      label: Text(clay.title),
                      selected: query.clayIds.contains(clay.id),
                      onSelected: (_) => update(query.copyWith(
                        clayIds: _toggle(query.clayIds, clay.id),
                      )),
                    )).toList(),
                  ),
                  _FilterSection(
                    title: context.l10n.glaze,
                    children: _controller.glazes.map((glaze) => FilterChip(
                      label: Text(glaze.title),
                      selected: query.glazeIds.contains(glaze.id),
                      onSelected: (_) => update(query.copyWith(
                        glazeIds: _toggle(query.glazeIds, glaze.id),
                      )),
                    )).toList(),
                  ),
                  _FilterSection(
                    title: context.l10n.minimumRating,
                    children: List.generate(5, (index) => ChoiceChip(
                      label: Text('${index + 1}+ ★'),
                      selected: query.minimumRating == index + 1,
                      onSelected: (selected) => update(query.copyWith(
                        minimumRating: selected ? index + 1 : 0,
                      )),
                    )),
                  ),
                  if (_controller.availableTags.isNotEmpty)
                    _FilterSection(
                      title: context.l10n.tags,
                      children: _controller.availableTags.map((tag) {
                        final normalized = tag.toLowerCase();
                        return FilterChip(
                          label: Text(tag),
                          selected: query.tags.contains(normalized),
                          onSelected: (_) => update(query.copyWith(
                            tags: _toggle(query.tags, normalized),
                          )),
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
    CeramicJournalSort.recentlyUpdated => context.l10n.sortRecentlyUpdated,
    CeramicJournalSort.title => context.l10n.title,
    CeramicJournalSort.rating => context.l10n.rating,
    CeramicJournalSort.stage => context.l10n.stage,
    CeramicJournalSort.created => context.l10n.creationDate,
  };
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: children),
    ]),
  );
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(children: [
      Icon(
        Icons.handyman_outlined,
        size: 54,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(height: 14),
      Text(
        context.l10n.startCeramicJournal,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 7),
      Text(context.l10n.emptyJournalDescription),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.createFirstPiece),
      ),
    ]),
  );
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(children: [
      Icon(
        Icons.search_off,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n.noMatchingPieces,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: onClear,
        child: Text(context.l10n.clearSearchAndFilters),
      ),
    ]),
  );
}
