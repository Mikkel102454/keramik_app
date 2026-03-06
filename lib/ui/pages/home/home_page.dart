import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/category_dto.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/ui/widgets/GridLayout.dart';
import 'package:ceramic_app/ui/widgets/SquareWidget.dart';
import 'home_page_controller.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CategoryController _controller;

  Future<void> _openCategory(CategoryDto category) async {
    if(category.page == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => category.page!(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = CategoryController();
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
        title: Text("Keramik App"),

        actions: [
          IconButton(
            icon: const Icon(Icons.settings),

            onPressed: () {

            },
          ),
        ],
      ),

      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_controller.error != null) {
              return Center(
                child: Text(_controller.error!),
              );
            }

            final items = [
              ..._controller.categories.map(
                    (cat) => SquareWidget(
                    title: cat.title,
                    onTap: () => _openCategory(cat),
                    ),
              ),
            ];

            return GridLayout(
              onRefresh: _controller.load,
              children: items,
            );
          },
        ),
      ),
    );
  }
}