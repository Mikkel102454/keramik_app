import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../categories/category.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 squares per row
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: Category.getCategoryCount(), // total squares
          itemBuilder: (context, index) {
            return Category.getCategory(index).draw(context);
          },
        ),
      ),
    );
  }
}