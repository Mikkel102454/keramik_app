import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_page.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_page.dart';
import 'package:ceramic_app/ui/widgets/v2/divider_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_row_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MaterialsPage extends StatelessWidget {
  const MaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Materials"),
        actions: [
        ],
      ),

      body: SafeArea(
        child: _pageContent()
      ),

      bottomNavigationBar:
      const NavigationWidget(
        currentPage: NavigationPage.materials,
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
              DividerWidget(),

              NavigationRowWidget(
                text: "Clays",
                navigation: const ClaysPage(),
              ),
              NavigationRowWidget(
                text: "Glazes",
                navigation: const GlazesPage(),
              ),
            ]
        )
    );
  }
}