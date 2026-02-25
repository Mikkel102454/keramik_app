import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kemik_app/classes/stage_dto.dart';
import 'package:kemik_app/pages/todo/settings_page.dart';
import 'package:kemik_app/ui/layouts/GridLayout.dart';
import 'package:kemik_app/ui/widgets/TitleWidget.dart';

import '../classes/category_dto.dart';
import '../network/ceramic.dart';
import '../ui/inputs/NumberInputWidget.dart';
import '../ui/inputs/TextInputWidget.dart';
import '../ui/widgets/SquareWidgetIcon.dart';

class CeramicCreatePage extends StatefulWidget {
  const CeramicCreatePage({
    super.key,
  });


  @override
  State<CeramicCreatePage> createState() => _CeramicCreatePageState();
}

class _CeramicCreatePageState extends State<CeramicCreatePage> {
  bool loading = true;

  late StageDto currentStep;
  int rating = 0;

  final List<TextEditingController> glazeControllers = [];

  final List<String> tags = [];

  List<CategoryDto> categoriesFromApi = [];
  final List<StageDto> stages = [];

  String selectedCategory = "";

  // ===================== INIT =====================

  @override
  void initState() {
    super.initState();
    _initNewCeramic();
  }

  Future<void> _initNewCeramic() async {
    try {
      final stagesData = await getStages();

      setState(() {

        stages
          ..clear()
          ..addAll(stagesData)
          ..sort((a, b) => a.id.compareTo(b.id));

        currentStep = stages.first;

        loading = false;
      });
    } catch (e) {
      debugPrint("Init error: $e");
    }
  }

  // ===================== CREATE =====================

  // Future<void> _createCeramic() async {
  //   final title = titleController.text.trim();
  //   final clay = clayController.text.trim();
  //
  //   final weight =
  //       double.tryParse(weightController.text.trim()) ?? 0.0;
  //
  //   final notes = notesController.text.trim();
  //
  //   if (title.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Enter a title")),
  //     );
  //     return;
  //   }
  //
  //   if (selectedCategory.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Select a category")),
  //     );
  //     return;
  //   }
  //
  //   final categoryId = categoriesFromApi
  //       .firstWhere((c) => c.title == selectedCategory);
  //
  //   final glazeNotes =
  //   glazeControllers.map((c) => c.text.trim()).toList();
  //
  //   try {
  //     await createCeramic(
  //       title: title,
  //       clayType: clay,
  //       weight: weight,
  //       note: notes,
  //       rating: rating,
  //       stageId: currentStep.id,
  //       tags: tags,
  //       glazes: glazeNotes,
  //     );
  //
  //     Navigator.pop(context, true);
  //
  //   } catch (e) {
  //     debugPrint("Create failed: $e");
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
  //     );
  //   }
  // }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: null,//_createCeramic,
        child: const Icon(Icons.check),
      ),

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("New Ceramic"),
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

      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageRow(),

            const SizedBox(height: 25),

            _buildProgress(),

            const SizedBox(height: 30),

            TitleWidget(title: "INFORMATION"),

            // TITLE FIELD
            TextInputWidget(
              label: "Title",
            ),
            TextInputWidget(
              label: "Clay Type",
            ),
            NumberInputWidget(
              label: "Weight",
              suffix: "kg",
            ),

            const SizedBox(height: 20),

            TitleWidget(title: "GLAZES"),

            _buildGlazeList(),

            const SizedBox(height: 25),

            _buildRating(),

            const SizedBox(height: 25),

            TitleWidget(title: "TAGS"),

            // _buildInlineTags(),

            const SizedBox(height: 30),

            TitleWidget(title: "NOTES"),

            // _buildNotes(),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ===================== IMAGE =====================

  Widget _buildImageRow() {
    List<Widget> children = [];

    for (int i = 0; i < 10; i++){
      children.add(
        SquareWidgetIcon(
          icon: i == 0
              ? Icons.camera_alt
              : Icons.image
        )
      );
    }
    return SizedBox(
      height: 100,

      child: GridLayout(
        crossAxisCount: 1,
        scrollDirection: Axis.horizontal,
        children: children,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ===================== PROGRESS =====================

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "PROGRESS",
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: List.generate(stages.length, (index) {
            final done = stages[index].id <= currentStep.id;

            return Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentStep = stages[index];
                      });
                    },

                    child: CircleAvatar(
                      radius: 14,

                      backgroundColor:
                      done ? Colors.green : Colors.grey,

                      child: done
                          ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    stages[index].title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  )
                ],
              ),
            );
          }),
        ),
      ],
    );
  }


  // ===================== GLAZES =====================

  Widget _buildGlazeList() {
    return Column(
      children: [
        ...List.generate(glazeControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),

            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: TextField(
                      controller: glazeControllers[index],
                      style: const TextStyle(color: Colors.white),

                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(14),
                        hintText: "Glaze note",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                IconButton(
                  onPressed: () {
                    setState(() {
                      glazeControllers.removeAt(index);
                    });
                  },

                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                )
              ],
            ),
          );
        }),

        Align(
          alignment: Alignment.centerLeft,

          child: TextButton.icon(
            onPressed: () {
              setState(() {
                glazeControllers.add(TextEditingController());
              });
            },

            icon: const Icon(Icons.add),
            label: const Text("Add glaze"),
          ),
        )
      ],
    );
  }

  // ===================== TAGS =====================

  // Widget _buildInlineTags() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //
  //     children: [
  //       Wrap(
  //         spacing: 8,
  //         runSpacing: 8,
  //
  //         children: List.generate(tags.length, (index) {
  //           return Chip(
  //             backgroundColor: Colors.grey[800],
  //
  //             label: Text(
  //               tags[index],
  //               style: const TextStyle(color: Colors.white),
  //             ),
  //
  //             deleteIconColor: Colors.white54,
  //
  //             onDeleted: () {
  //               setState(() {
  //                 tags.removeAt(index);
  //               });
  //             },
  //           );
  //         }),
  //       ),
  //
  //       const SizedBox(height: 10),
  //
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 color: Colors.grey[900],
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //
  //               child: TextField(
  //                 controller: tagController,
  //                 style: const TextStyle(color: Colors.white),
  //
  //                 decoration: const InputDecoration(
  //                   contentPadding: EdgeInsets.all(12),
  //                   hintText: "Add tag...",
  //                   hintStyle: TextStyle(color: Colors.white38),
  //                   border: InputBorder.none,
  //                 ),
  //
  //                 onSubmitted: (_) => _addTag(),
  //               ),
  //             ),
  //           ),
  //
  //           const SizedBox(width: 8),
  //
  //           IconButton(
  //             onPressed: _addTag,
  //             icon: const Icon(Icons.add_circle),
  //             color: Colors.green,
  //           ),
  //         ],
  //       )
  //     ],
  //   );
  // }

  // void _addTag() {
  //   final text = tagController.text.trim();
  //
  //   if (text.isEmpty) return;
  //
  //   setState(() {
  //     tags.add(text);
  //     tagController.clear();
  //   });
  // }

  // ===================== RATING =====================

  Widget _buildRating() {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          padding: EdgeInsets.zero,

          onPressed: () {
            setState(() {
              rating = index + 1;
            });
          },

          icon: Icon(
            Icons.star,
            color:
            index < rating ? Colors.green : Colors.grey,
          ),
        );
      }),
    );
  }

  // ===================== NOTES =====================

  // Widget _buildNotes() {
  //   return TextField(
  //     controller: notesController,
  //     maxLines: 6,
  //     style: const TextStyle(color: Colors.white),
  //
  //     decoration: InputDecoration(
  //       hintText: "Write notes...",
  //       hintStyle: const TextStyle(color: Colors.white38),
  //       filled: true,
  //       fillColor: Colors.grey[900],
  //
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide.none,
  //       ),
  //     ),
  //   );
  // }

  // ===================== CLEANUP =====================

  @override
  void dispose() {
    super.dispose();
  }
}