import 'package:ceramic_app/ui/pages/materials/clays/clays_create/clays_create_page.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_page_controller.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_view/clays_view_page.dart';
import 'package:ceramic_app/ui/widgets/extends/smart_row.dart';
import 'package:ceramic_app/ui/widgets/v2/divider_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';

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
        title: const Text("Clays"),
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

  SingleChildScrollView _pageContent(ClaysPageController controller) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextWidget(text: "Clay Bodies", fontSize: 20, fontWeight: FontWeight.bold,),
        const SizedBox(height: 16),

        DividerWidget(),
        const SizedBox(height: 16),

        for (final clay in controller.clayTypes) ... [
          SmartRow(
            children: [
              SquareWidget(
                width: 80,
                height: 80,
                backgroundColor: Colors.grey.shade300,
                imageUri: clay.images.isNotEmpty ? clay.images[0].uri : null,
                icon: clay.images.isEmpty ? Icons.image_not_supported : null,
                iconColor: Colors.grey.shade500,
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
          backgroundColor: Colors.grey.shade300,
          iconColor: Colors.black,
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
