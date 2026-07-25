import 'package:ceramic_app/ui/pages/materials/clays/clays_create/clays_create_page.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_page_controller.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_view/clays_view_page.dart';
import 'package:ceramic_app/ui/widgets/extends/smart_row.dart';
import 'package:ceramic_app/ui/widgets/v2/divider_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.clays),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
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
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  context.l10n.errorWithDetails('${_controller.error}'),
                ),
                FilledButton(
                  onPressed: _controller.load,
                  child: Text(context.l10n.retry),
                ),
              ]));
            }

            return RefreshIndicator(
              onRefresh: _controller.load,
              child: _pageContent(_controller),
            );
          },
        ),
      ),
    );
  }

  SingleChildScrollView _pageContent(ClaysPageController controller) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextWidget(
          text: context.l10n.clayBodies,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 16),

        DividerWidget(),
        const SizedBox(height: 16),

        for (final clay in controller.clayTypes) ... [
          SmartRow(
            children: [
              SquareWidget(
                width: 80,
                height: 80,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                imageUri: clay.images.isNotEmpty ? clay.images[0].uri : null,
                icon: clay.images.isEmpty ? Icons.image_not_supported : null,
                iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                iconSize: 38,
              ),
              const SizedBox(width: 16),
              TextWidget(text: clay.title, fontSize: 20, fontWeight: FontWeight.bold,),
            ],
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ClaysViewPage(clay: clay,)
                ),
              );

              if (result == true) {
                setState(() {
                  _controller.load();
                });
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        SquareWidget(
          height: 60,
          icon: Icons.add,
          iconSize: 30,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          iconColor: Theme.of(context).colorScheme.onSurface,
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ClaysCreatePage()
              ),
            );

            if (result == true) {
              setState(() {
                _controller.load();
              });
            }
          },
        ),
        const SizedBox(height: 40),
      ]),
    );
  }
}
