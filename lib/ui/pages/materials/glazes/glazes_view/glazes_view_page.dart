import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_view/glazes_view_page_controller.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';

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
          title: const Text('Glaze'),
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
                return Center(child: Text('Error: ${_controller.error}'));
              }
              return RefreshIndicator(
                onRefresh: () => _controller.load(null),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextWidget(
                        text: 'Information',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Title',
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 4),
                      TextFieldWidget(
                        placeholder: 'Title',
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
        title: const Text('Delete glaze'),
        content: const Text('Are you sure you want to delete this glaze?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
        title: const Text('Glaze cannot be deleted'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
