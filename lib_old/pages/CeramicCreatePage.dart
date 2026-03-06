import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kemik_app/classes/stage_dto.dart';
import 'package:kemik_app/features/ceramics/logic/CeramicCreateController.dart';
import 'package:kemik_app/pages/todo/settings_page.dart';
import 'package:kemik_app/ui/inputs/GlazeListWidget.dart';
import 'package:kemik_app/ui/inputs/InlineTagsWidget.dart';
import 'package:kemik_app/ui/inputs/TextareaWidget.dart';
import 'package:kemik_app/ui/layouts/GridLayout.dart';
import 'package:kemik_app/ui/widgets/ProgressStepperWidget.dart';
import 'package:kemik_app/ui/widgets/RatingWidget.dart';
import 'package:kemik_app/ui/widgets/TitleWidget.dart';

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
  final CeramicCreateController _controller = CeramicCreateController();

  final List<StageDto> stages = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _clayTypeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

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

        _controller.stage = stages.first;

        loading = false;
      });
    } catch (e) {
      debugPrint("Init error: $e");
    }
  }

  // ===================== CREATE =====================

  Future<void> _createCeramic() async {
    if (_controller.title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a title")),
      );
      return;
    }

    try {
      _controller.create();

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Create failed: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

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
        onPressed: _createCeramic,
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
            TitleWidget(title: "PROGRESS"),
            ProgressStepperWidget(
              stages: stages,
              currentStep: _controller.stage!,
              onChanged: (stage) {
                setState(() {
                  _controller.stage = stage;
                });
              },
            ),
            const SizedBox(height: 30),
            TitleWidget(title: "INFORMATION"),
            TextInputWidget(
              label: "Title",
              controller: _titleController,
              onChanged: (value) {
                setState(() {
                  _controller.title = value;
                });
              },
            ),
            TextInputWidget(
              label: "Clay Type",
              controller: _clayTypeController,
              onChanged: (value) {
                setState(() {
                  _controller.clayType = value;
                });
              },
            ),
            NumberInputWidget(
              label: "Weight",
              controller: _weightController,
              suffix: "kg",
              onChanged: (value) {
                setState(() {
                  _controller.weight = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 20),
            TitleWidget(title: "GLAZES"),
            GlazeListWidget(
              onUpdate: (index, value) async {
                await _controller.updateGlaze(index, value);
              },
              onAdd: (index, controller) async {
                await _controller.addGlaze(index);
              },
              onRemove: (index, value) async {
                await _controller.removeGlaze(index);
              },
              glazes: [],
            ),
            const SizedBox(height: 15),
            RatingWidget(
              title: "Rating:",
              rating: _controller.rating,
              onChanged: (newRating) {
                setState(() {
                  _controller.rating = newRating;
                });
              },
            ),
            const SizedBox(height: 25),
            TitleWidget(title: "TAGS"),
            InlineTagsWidget(
              onChanged: (updatedTags) {
                setState(() {
                  _controller.tags = updatedTags;
                });
              },
            ),
            const SizedBox(height: 30),
            TitleWidget(title: "NOTES"),
            TextAreaWidget(
              hint: "Write notes...",
              controller: _notesController,
              minLines: 4,
              onChanged: (value) {
                setState(() {
                  _controller.notes = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildImageRow() {
    List<Widget> children = [];

    for (int i = 0; i < 10; i++) {
      children.add(SquareWidgetIcon(
          icon: i == 0 ? Icons.camera_alt : Icons.image));
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

  @override
  void dispose() {
    _titleController.dispose();
    _clayTypeController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
