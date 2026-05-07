import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/category_dto.dart';
import 'package:ceramic_app/ui/pages/login/login_page.dart';
import 'package:ceramic_app/ui/widgets/v2/accordion_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/divider_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_row_widget.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';

@RoutePage()
class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {

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
  }

  @override
  void dispose() {
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(text: "Header", fontWeight: FontWeight.bold, fontSize: 32),
              TextWidget(text: "Header", fontWeight: FontWeight.bold, fontSize: 26),
              TextWidget(text: "Header", fontWeight: FontWeight.bold, fontSize: 20),
              TextWidget(text: "Header", fontWeight: FontWeight.normal, fontSize: 14),
              const SizedBox(height: 25),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: SquareWidget(
                        title: 'Default',
                        icon: Icons.home,
                        onTap: () {},
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 120,
                      child: SquareWidget(
                        title: 'Horizontal',
                        icon: Icons.settings,
                        direction: Axis.horizontal,
                        spacing: 12,
                        backgroundColor: Colors.green,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
              AccordionWidget(
                title: "Glazed",
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    5,
                        (index) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              AccordionWidget(
                title: "Glazed",
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    5,
                        (index) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              NavigationRowWidget(
                text: "Clays",
                navigation: const LoginPage(),
              ),
            ]
          ),
        ),
      ),
    );
  }
}