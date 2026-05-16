import 'package:ceramic_app/ui/pages/materials/glazes/glazes_create/glazes_create_page_controller.dart';
import 'package:flutter/material.dart';

class GlazesCreatePage extends StatefulWidget {
  const GlazesCreatePage({super.key});

  @override
  State<GlazesCreatePage> createState() => _GlazesCreatePageState();
}

class _GlazesCreatePageState extends State<GlazesCreatePage> {
  final GlazesCreatePageController _controller = GlazesCreatePageController();

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
        title: const Text("Ceramic View"),
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
              return Center(child: Text("Error: ${_controller.error}"));
            }

            return RefreshIndicator(
              onRefresh: () async {
                _controller.load();
              },
              child: _pageContent(_controller),
            );
          },
        ),
      ),
    );
  }

  SingleChildScrollView _pageContent(GlazesCreatePageController controller) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: []),
    );
  }
}
