import 'package:flutter/material.dart';
import 'package:ceramic_app/ui/widgets/v2/ui_library.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/glaze_notebook_dto.dart';
import 'glaze_notebook_controller.dart';
import 'glaze_notebook_editor_page.dart';
import 'glaze_notebook_detail_page.dart';

class GlazeNotebookPage extends StatefulWidget {
  const GlazeNotebookPage({
    super.key,
    required this.tiles,
    this.selectRecipe = false,
  });
  final bool tiles;
  final bool selectRecipe;
  @override
  State<GlazeNotebookPage> createState() => _GlazeNotebookPageState();
}

class _GlazeNotebookPageState extends State<GlazeNotebookPage> {
  late final GlazeNotebookController controller;
  bool _filtersExpanded = false;
  @override
  void initState() {
    super.initState();
    controller = GlazeNotebookController(tiles: widget.tiles)..load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _open(GlazeNotebookDto item) async {
    final value = await controller.detail(item.id);
    if (!mounted || value == null) return;
    if (widget.selectRecipe) {
      Navigator.pop(context, value);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GlazeNotebookDetailPage(value: value, controller: controller),
      ),
    );
    if (mounted) await controller.load();
  }

  Future<void> _create() async {
    GlazeNotebookDto? initial;
    if (widget.tiles && controller.recipes.isNotEmpty) {
      final selected = await showDialog<GlazeNotebookDto>(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text(context.l10n.sourceRecipe),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(
                c,
                GlazeNotebookDto(name: '', layers: [], firings: []),
              ),
              child: Text(context.l10n.notSet),
            ),
            for (final recipe in controller.recipes)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(c, recipe.tileDraft()),
                child: Text('${recipe.name} · v${recipe.version}'),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c),
              child: Text(context.l10n.cancel),
            ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      initial = selected;
    }
    final saved = await Navigator.push<GlazeNotebookDto>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GlazeNotebookEditorPage(controller: controller, value: initial),
      ),
    );
    if (saved != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              GlazeNotebookDetailPage(value: saved, controller: controller),
        ),
      );
      if (mounted) await controller.load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.tiles
            ? context.l10n.testTileNotebook
            : context.l10n.glazeCombinations,
      ),
    ),
    body: SafeArea(
      child: StudioContent(
        maxWidth: 900,
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, _) => RefreshIndicator(
            onRefresh: () => controller.load(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StudioSurface(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFieldWidget(
                                      semanticsLabel:
                                          context.l10n.notebookSearch,
                                      placeholder: context.l10n.notebookSearch,
                                      suffixIcon: const Icon(Icons.search),
                                      onSubmitted: (v) async {
                                        controller.search = v;
                                        await controller.load();
                                        return true;
                                      },
                                    ),
                                  ),
                                  if (widget.tiles) ...[
                                    const SizedBox(width: 8),
                                    Badge(
                                      isLabelVisible:
                                          controller.recipeId != null ||
                                          controller.clayId != null,
                                      label: Text(
                                        '${(controller.recipeId == null ? 0 : 1) + (controller.clayId == null ? 0 : 1)}',
                                      ),
                                      child: IconButton(
                                        tooltip: context.l10n.filters,
                                        isSelected: _filtersExpanded,
                                        onPressed: () => setState(
                                          () => _filtersExpanded =
                                              !_filtersExpanded,
                                        ),
                                        icon: const Icon(Icons.tune),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (widget.tiles && _filtersExpanded) ...[
                                const SizedBox(height: 8),
                                SelectFieldWidget<int>(
                                  value: controller.recipeId,
                                  label: context.l10n.filterRecipe,
                                  items: [
                                    DropdownMenuItem<int>(
                                      value: null,
                                      child: Text(context.l10n.allRecipes),
                                    ),
                                    ...controller.recipeNames.entries.map(
                                      (r) => DropdownMenuItem(
                                        value: r.key,
                                        child: Text(r.value),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    controller.recipeId = v;
                                    controller.load();
                                  },
                                ),
                                const SizedBox(height: 8),
                                SelectFieldWidget<int>(
                                  value: controller.clayId,
                                  label: context.l10n.clay,
                                  items: [
                                    DropdownMenuItem<int>(
                                      value: null,
                                      child: Text(context.l10n.allClays),
                                    ),
                                    ...controller.clays.map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.title),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    controller.clayId = v;
                                    controller.load();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (controller.loading) const LinearProgressIndicator(),
                        if (controller.failed) ...[
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.notebookFailed,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => controller.load(),
                            icon: const Icon(Icons.refresh),
                            label: Text(context.l10n.retry),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!controller.loading &&
                    !controller.failed &&
                    controller.items.isEmpty)
                  SliverToBoxAdapter(
                    child: StudioEmptyState(
                      icon: widget.tiles
                          ? Icons.science_outlined
                          : Icons.layers_outlined,
                      title: context.l10n.notebookEmpty,
                      action: widget.selectRecipe
                          ? null
                          : FilledButton.icon(
                              onPressed: _create,
                              icon: const Icon(Icons.add),
                              label: Text(
                                widget.tiles
                                    ? context.l10n.createTestTile
                                    : context.l10n.createCombination,
                              ),
                            ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverList.builder(
                    itemCount: controller.items.length,
                    itemBuilder: (context, index) {
                      final item = controller.items[index];
                      return Card(
                        key: ValueKey(item.id),
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        shape: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Icon(
                            widget.tiles
                                ? Icons.science_outlined
                                : Icons.layers_outlined,
                          ),
                          title: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            [
                              if (item.sourceName != null)
                                '${item.sourceName} \u00b7 v${item.sourceVersion}',
                              if (item.clayTitle != null) item.clayTitle!,
                            ].join(' \u00b7 '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(item),
                        ),
                      );
                    },
                  ),
                ),
                if (controller.cursor != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: OutlinedButton(
                        onPressed: controller.loading
                            ? null
                            : () => controller.load(more: true),
                        child: Text(context.l10n.loadMore),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    ),
    floatingActionButton: widget.selectRecipe
        ? null
        : AnimatedBuilder(
            animation: controller,
            builder: (_, _) => FloatingActionButton(
              tooltip: widget.tiles
                  ? context.l10n.createTestTile
                  : context.l10n.createCombination,
              onPressed: controller.loading ? null : _create,
              child: const Icon(Icons.add),
            ),
          ),
  );
}
