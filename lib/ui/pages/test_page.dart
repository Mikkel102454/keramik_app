import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/ui/pages/login/login_page.dart';
import 'package:ceramic_app/ui/widgets/v2/accordion_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/glaze_input_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_row_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/star_stepper_select_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/stepper_select_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/tag_input_widget.dart';
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
                        onPressed: () async {},
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
                        onPressed: () async {},
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
                  TextFieldWidget(
                    placeholder: "Title",
                    debounceDuration: Duration(seconds: 2),
                    onChanged: (value) async {
                      debugPrint(value.toString());

                      await Future.delayed(
                        const Duration(milliseconds: 500),
                      );

                      return false;
                    },
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
                placeholder: "Select",

                entries: [
                  MapEntry("Stoneware", "STONEWARE"),
                  MapEntry("Porcelain", "PORCELAIN"),
                  MapEntry("Terracotta", "TERRACOTTA"),
                ],

                onChanged: (value) async {
                  debugPrint(value);

                  await Future.delayed(
                    const Duration(milliseconds: 500),
                  );

                  // return false to revert
                  return false;
                },
              ),
              const SizedBox(height: 16),

              StepperSelectWidget(
                initialValue: "trimmed",

                size: 40,
                entries: const [
                  MapEntry("Idea", "idea"),
                  MapEntry("Thrown", "thrown"),
                  MapEntry("Trimmed", "trimmed"),
                  MapEntry("Bisqued", "bisqued"),
                  MapEntry("Glazed", "glazed"),
                  MapEntry("Finished", "finished"),
                ],

                onChanged: (value) async {
                  debugPrint(value);

                  await Future.delayed(
                    const Duration(milliseconds: 500),
                  );

                  // return false to revert
                  return true;
                },
              ),
              const SizedBox(height: 16),

              StarStepperSelectWidget(
                initialValue: 3,

                selectedIconColor: Colors.green,

                onChanged: (value) async {
                  debugPrint(value.toString());

                  await Future.delayed(
                    const Duration(milliseconds: 500),
                  );

                  return true;
                },
              ),
              const SizedBox(height: 16),

              TagInputWidget(
                initialValues: const [
                  TagEntry(id: 1, value: "Ceramic"),
                  TagEntry(id: 2, value: "Pottery"),
                  TagEntry(id: 3, value: "Clay"),
                ],

                horizontalPadding: 4,
                verticalPadding: 6,

                borderRadius: 5,

                fontSize: 10,
                fontWeight: FontWeight.w700,

                borderColor: Colors.blue,
                backgroundColor: Colors.blue.shade50,

                removeIconSize: 13,
                removeIconColor: Colors.red,
              ),
              const SizedBox(height: 16),

              GlazeInputWidget(
                glazeEntries: const [
                  MapEntry("Transparent", 1),
                  MapEntry("Matte White", 2),
                  MapEntry("Ocean Blue", 3),
                  MapEntry("Iron Black", 4),
                  MapEntry("Copper Red", 5),
                ],

                initialValues: const [
                  GlazeEntry(
                    id: 101,
                    glazeId: 2,
                    glazeName: "Matte White",
                    notes: "Use 3 coats",
                    expanded: false,
                  ),

                  GlazeEntry(
                    id: 102,
                    glazeId: 4,
                    glazeName: "Iron Black",
                    notes: "Breaks brown on edges",
                    expanded: true,
                  ),
                ],

                onCreate: (glazeId) async {
                  await Future.delayed(
                    const Duration(milliseconds: 500),
                  );

                  /// return new glaze entry id
                  return DateTime.now()
                      .millisecondsSinceEpoch;
                },

                onDelete: (glazeEntryId) async {
                  await Future.delayed(
                    const Duration(milliseconds: 400),
                  );

                  debugPrint(
                    "Deleting glaze entry: $glazeEntryId",
                  );

                  /// return false to revert
                  return true;
                },

                onNotesChanged: (
                    glazeEntryId,
                    notes,
                    ) async {
                  await Future.delayed(
                    const Duration(milliseconds: 300),
                  );

                  debugPrint(
                    "Updating notes for $glazeEntryId: $notes",
                  );

                  /// return false to revert
                  return true;
                },
              )
            ]
          ),
        ),
      ),
      bottomNavigationBar:
      const NavigationWidget(
        currentPage: NavigationPage.home,
      ),
    );
  }
}