import 'package:clay_dock/objects/glaze_dto.dart';
import 'package:clay_dock/ui/pages/materials/glazes/glazes_view/glazes_view_page_controller.dart';
import 'package:clay_dock/ui/widgets/v2/ui_library.dart';
import 'package:clay_dock/ui/pages/materials/glazes/glazes_create/glazes_create_page.dart';
import 'package:flutter/material.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';

class GlazesViewPage extends StatefulWidget {
  final GlazeDto glaze;

  const GlazesViewPage({super.key, required this.glaze});

  @override
  State<GlazesViewPage> createState() => _GlazesViewPageState();
}

class _GlazesViewPageState extends State<GlazesViewPage> {
  final GlazesViewPageController _controller = GlazesViewPageController();

  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _controller.load(widget.glaze);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editGlaze() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GlazesCreatePage(glaze: _controller.glaze),
      ),
    );
    if (saved == true && mounted) {
      _controller.hasChanged = true;
      await _controller.load(null);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_deleting) {
        Navigator.of(context).pop(_controller.hasChanged);
      }
    },
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => EntryPage(
        title: _controller.glaze.title,
        onBack: () => Navigator.of(context).pop(_controller.hasChanged),
        onEdit: _editGlaze,
        onDelete: _deleteGlaze,
        busy: _controller.isLoading || _deleting,
        error: _controller.error == null ? null : context.l10n.notebookFailed,
        onRetry: () => _controller.load(null),
        onRefresh: () => _controller.load(null),
        children: [
          EntrySection(
            title: context.l10n.information,
            children: [
              EntryValue(
                label: context.l10n.title,
                value: _controller.glaze.title,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _deleteGlaze() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteGlaze),
        content: Text(context.l10n.deleteGlazeQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);

    final error = await _controller.deleteGlaze();
    if (!mounted) return;
    setState(() => _deleting = false);
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.glazeCannotDelete),
        content: Text(context.l10n.operationFailed),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }
}
