import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_view/glazes_view_page_controller.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class GlazesViewPage extends StatefulWidget {
  final GlazeDto glaze;

  const GlazesViewPage({super.key, required this.glaze});

  @override
  State<GlazesViewPage> createState() => _GlazesViewPageState();
}

class _GlazesViewPageState extends State<GlazesViewPage> {
  final GlazesViewPageController _controller = GlazesViewPageController();

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_controller.hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.glaze),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_controller.hasChanged),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: _deleteGlaze,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {},
            ),
          ],
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
                  child: Text(
                    context.l10n.errorWithDetails('${_controller.error}'),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => _controller.load(null),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: context.l10n.information,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: context.l10n.title,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      TextFieldWidget(
                        placeholder: context.l10n.title,
                        initialValue: _controller.glaze.title,
                        debounceDuration: const Duration(milliseconds: 300),
                        onChanged: (value) async {
                          if (value.trim().isEmpty) return false;
                          return _controller.setTitle(value);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

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
    if (confirmed != true) return;

    final error = await _controller.deleteGlaze();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.glazeCannotDelete),
        content: Text(error),
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
