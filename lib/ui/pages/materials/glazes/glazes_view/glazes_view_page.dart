import 'package:ceramic_app/ui/pages/materials/glazes/glazes_view/glazes_view_page_controller.dart';
import 'package:flutter/material.dart';

class GlazesViewPage extends StatefulWidget {
  const GlazesViewPage({super.key});

  @override
  State<GlazesViewPage> createState() => _GlazesViewPageState();
}

class _GlazesViewPageState extends State<GlazesViewPage> {
  final GlazesViewPageController _controller = GlazesViewPageController();

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

  SingleChildScrollView _pageContent(GlazesViewPageController controller) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: []),
    );
  }
}
