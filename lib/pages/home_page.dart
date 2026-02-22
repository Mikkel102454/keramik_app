import 'package:flutter/material.dart';
import 'package:kemik_app/categories/category.dart';
import 'package:kemik_app/classes/category.dart';
import 'package:kemik_app/network/category.dart';
import '../config/constants.dart';
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

      body: FutureBuilder<CategoryList>(
        future: fetchCategories(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          // Success
          if (snapshot.hasData) {
            final categoryList = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),

                itemCount: categoryList.categories.length,

                itemBuilder: (context, index) {
                  Category category = new Category();
                  category.id = categoryList.categories[index].id;
                  category.title = categoryList.categories[index].title;

                  return category.draw(context);
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}