import 'package:ceramic_app/ui/pages/materials/clays/clays_create/clays_create_page.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_page_controller.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_view/clays_view_page.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/studio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class ClaysPage extends StatefulWidget {
  const ClaysPage({super.key});

  @override
  State<ClaysPage> createState() => _ClaysPageState();
}

class _ClaysPageState extends State<ClaysPage> {
  final ClaysPageController _controller = ClaysPageController();

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

  Future<void> _createClay() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ClaysCreatePage()),
    );
    if (created == true && mounted) await _controller.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.clays)),
    floatingActionButton: FloatingActionButton(
      tooltip: context.l10n.create,
      onPressed: _createClay,
      child: const Icon(Icons.add),
    ),
    body: SafeArea(
      child: StudioContent(
        maxWidth: 900,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading && _controller.clayTypes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.error != null && _controller.clayTypes.isEmpty) {
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
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_controller.isLoading)
                    const SliverToBoxAdapter(child: LinearProgressIndicator()),
                  if (_controller.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          context.l10n.operationFailed,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  if (_controller.clayTypes.isEmpty)
                    SliverToBoxAdapter(
                      child: StudioEmptyState(
                        icon: Icons.landscape_outlined,
                        title: context.l10n.notebookEmpty,
                        action: FilledButton.icon(
                          onPressed: _createClay,
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.create),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.zero,
                    sliver: SliverList.builder(
                      itemCount: _controller.clayTypes.length,
                      itemBuilder: (context, index) {
                        final clay = _controller.clayTypes[index];
                        return Card(
                          key: ValueKey(clay.id),
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: SquareWidget(
                              width: 52,
                              height: 52,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              imageUri: clay.images.isEmpty
                                  ? null
                                  : clay.images.first.uri,
                              icon: clay.images.isEmpty
                                  ? Icons.landscape_outlined
                                  : null,
                              iconColor: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              iconSize: 26,
                            ),
                            title: Text(
                              clay.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: clay.supplier.isEmpty
                                ? null
                                : Text(clay.supplier),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClaysViewPage(clay: clay),
                                ),
                              );
                              if (changed == true && mounted) {
                                await _controller.load();
                              }
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
          },
        ),
      ),
    ),
  );
}
