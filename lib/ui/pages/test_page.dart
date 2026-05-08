import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/category_dto.dart';
import 'package:ceramic_app/ui/pages/login/login_page.dart';
import 'package:ceramic_app/ui/widgets/v2/accordion_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/divider_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_row_widget.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:flutter/services.dart';

import '../widgets/v2/dropdown_widget.dart';
import '../widgets/v2/text_field_widget.dart';

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
              const SizedBox(height: 25),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Basic title field
                  const TextFieldWidget(
                    placeholder: "Title",
                  ),

                  const SizedBox(height: 16),

                  // 2. Weight field with suffix
                  TextFieldWidget(
                    placeholder: "0.0",
                    initialValue: "1.0",
                    suffix: "kg",
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Multi-line notes field
                  const TextFieldWidget(
                    placeholder: "Notes",
                    minLines: 4,
                    maxLines: 6,
                  ),

                  const SizedBox(height: 16),

                  // 4. Password field
                  const TextFieldWidget(
                    placeholder: "Password",
                    obscureText: true,
                  ),

                  const SizedBox(height: 16),

                  // 5. Field with validation
                  TextFieldWidget(
                    placeholder: "Piece name",

                    autovalidateMode: AutovalidateMode.onUserInteraction,

                    validator: (text, context) {
                      if (text == null || text.trim().isEmpty) {
                        return "Required";
                      }

                      if (text.length < 3) {
                        return "Must be at least 3 characters";
                      }

                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownWidget(
                placeholder: "Clay Type",

                entries: [
                  MapEntry("Stoneware", "STONEWARE"),
                  MapEntry("Porcelain", "PORCELAIN"),
                  MapEntry("Terracotta", "TERRACOTTA"),
                ],

                onChanged: (value) async {
                  debugPrint(value);
                },
              ),
            ]
          ),
        ),
      ),
    );
  }
}