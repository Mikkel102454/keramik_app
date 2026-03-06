import 'package:flutter/material.dart';
import 'package:kemik_app/classes/category_dto.dart';
import 'package:kemik_app/ui/layouts/GridLayout.dart';
import 'package:kemik_app/ui/widgets/SquareWidget.dart';

import '../config/constants.dart';
import '../features/categories/logic/CategoryController.dart';
import 'PageManager.dart';
import 'WIPPage.dart';
import 'todo/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CategoryController _controller;

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

  Future<void> _openCategory(CategoryDto category) async {
    if(category.page == null) return;
    PageManager(context).openPage(category.page!());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),

        actions: [
          IconButton(
            icon: const Icon(Icons.settings),

            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: AnimatedBuilder(
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
    );
  }
}