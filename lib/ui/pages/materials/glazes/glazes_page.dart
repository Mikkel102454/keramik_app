import 'package:ceramic_app/ui/pages/materials/glazes/notebook/glaze_notebook_page.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_create/glazes_create_page.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_page_controller.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_view/glazes_view_page.dart';
import 'package:ceramic_app/ui/widgets/v2/entry_page_widgets.dart';
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
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.errorWithDetails('${_controller.error}')),
                    FilledButton(
                      onPressed: _controller.load,
                      child: Text(context.l10n.retry),
                    ),
                  ],
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

  SingleChildScrollView _pageContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: Text(context.l10n.glazeCombinations),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GlazeNotebookPage(tiles: false),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: Text(context.l10n.testTileNotebook),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GlazeNotebookPage(tiles: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          EntrySection(
            title: context.l10n.glazes,
            children: [
              if (_controller.glazes.isEmpty) Text(context.l10n.notebookEmpty),
              for (final glaze in _controller.glazes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(glaze.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GlazesViewPage(glaze: glaze),
                      ),
                    );
                    if (changed == true) await _controller.load();
                  },
                ),
            ],
          ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Future<void> _createGlaze() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GlazesCreatePage()),
    );
    if (created == true && mounted) await _controller.load();
  }
}
