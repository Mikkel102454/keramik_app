import 'package:ceramic_app/ui/pages/materials/glazes/glazes_create/glazes_create_page.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_page_controller.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_view/glazes_view_page.dart';
import 'package:ceramic_app/ui/widgets/extends/smart_row.dart';
import 'package:ceramic_app/ui/widgets/v2/divider_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';

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
        title: const Text('Glazes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
              return Center(child: Text('Error: ${_controller.error}'));
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
          const TextWidget(
            text: 'Glazes',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 16),
          const DividerWidget(),
          const SizedBox(height: 16),
          for (final glaze in _controller.glazes) ...[
            SmartRow(
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GlazesViewPage(glaze: glaze),
                  ),
                );
                if (changed == true) await _controller.load();
              },
              children: [
                SquareWidget(
                  width: 80,
                  height: 80,
                  backgroundColor: Colors.grey.shade300,
                  icon: Icons.opacity,
                  iconColor: Colors.grey.shade500,
                  iconSize: 38,
                ),
                const SizedBox(width: 16),
                TextWidget(
                  text: glaze.title,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SquareWidget(
            height: 60,
            icon: Icons.add,
            iconSize: 30,
            backgroundColor: Colors.grey.shade300,
            iconColor: Colors.black,
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const GlazesCreatePage()),
              );
              if (created == true) await _controller.load();
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
