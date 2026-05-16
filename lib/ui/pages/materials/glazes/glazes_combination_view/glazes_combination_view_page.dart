import 'package:ceramic_app/ui/pages/materials/glazes/glazes_combination_view/glazes_combination_view_page_controller.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_page_controller.dart';
import 'package:flutter/material.dart';

class GlazesCombinationViewPage extends StatefulWidget {
  const GlazesCombinationViewPage({super.key});

  @override
  State<GlazesCombinationViewPage> createState() => _GlazesCombinationViewPageState();
}

class _GlazesCombinationViewPageState extends State<GlazesCombinationViewPage> {
  final GlazesCombinationViewPageController _controller = GlazesCombinationViewPageController();

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

  SingleChildScrollView _pageContent(GlazesCombinationViewPageController controller) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: []),
    );
  }
}
