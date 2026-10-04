import 'package:ceramic_app/ui/pages/materials/glazes/notebook/glaze_notebook_page.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_create/glazes_create_page.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_page_controller.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_view/glazes_view_page.dart';
import 'package:ceramic_app/ui/widgets/v2/studio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class GlazesPage extends StatefulWidget {
  const GlazesPage({super.key});

  @override
  State<GlazesPage> createState() => _GlazesPageState();
}

class _GlazesPageState extends State<GlazesPage> {
  final GlazesPageController _controller = GlazesPageController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.glazes),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => FloatingActionButton(
          tooltip: context.l10n.createGlaze,
          onPressed: _controller.isLoading ? null : _createGlaze,
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading && _controller.glazes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.error != null && _controller.glazes.isEmpty) {
              return StudioEmptyState(
                icon: Icons.cloud_off_outlined,
                title: context.l10n.operationFailed,
                action: FilledButton.icon(
                  onPressed: _controller.load,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.retry),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _controller.load,
              child: _pageContent(),
            );
          },
        ),
      ),
    );
  }

  Widget _pageContent() => StudioContent(
    maxWidth: 900,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                StudioFeatureTile(
                  title: context.l10n.glazeCombinations,
                  icon: Icons.layers_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GlazeNotebookPage(tiles: false),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StudioFeatureTile(
                  title: context.l10n.testTileNotebook,
                  icon: Icons.science_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GlazeNotebookPage(tiles: true),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                if (_controller.isLoading) const LinearProgressIndicator(),
                if (_controller.error != null)
                  Text(
                    context.l10n.operationFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_controller.glazes.isEmpty)
          SliverToBoxAdapter(
            child: StudioEmptyState(
              icon: Icons.opacity_outlined,
              title: context.l10n.notebookEmpty,
              action: FilledButton.icon(
                onPressed: _createGlaze,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.createGlaze),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.zero,
          sliver: SliverList.builder(
            itemCount: _controller.glazes.length,
            itemBuilder: (context, index) {
              final glaze = _controller.glazes[index];
              return Card(
                key: ValueKey(glaze.id),
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
                  leading: const Icon(Icons.opacity_outlined),
                  title: Text(
                    glaze.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GlazesViewPage(glaze: glaze),
                      ),
                    );
                    if (changed == true && mounted) await _controller.load();
                  },
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    ),
  );

  Future<void> _createGlaze() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GlazesCreatePage()),
    );
    if (created == true && mounted) await _controller.load();
  }
}
