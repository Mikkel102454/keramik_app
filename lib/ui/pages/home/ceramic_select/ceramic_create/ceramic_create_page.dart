import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';
import 'package:ceramic_app/ui/widgets/GridLayout.dart';
import 'package:ceramic_app/ui/widgets/SquareWidget.dart';
import 'package:ceramic_app/ui/widgets/adaptive/adaptive_text_field.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/ui/pages/home/ceramic_select/widget/ProgressStepperWidget.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_select/widget/TitleWidget.dart';
import '../widget/GlazeListWidget.dart';
import '../widget/InlineTagsWidget.dart';
import '../widget/RatingWidget.dart';
import 'ceramic_create_page_controller.dart';

class CeramicCreatePage extends StatefulWidget {
  const CeramicCreatePage({
    super.key,
  });

  @override
  State<CeramicCreatePage> createState() => _CeramicCreatePageState();
}

class _CeramicCreatePageState extends State<CeramicCreatePage> {
  final CeramicCreatePageController _controller = CeramicCreatePageController();

  @override
  void initState() {
    super.initState();
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async => await _createCeramic(),
        child: const Icon(Icons.check),
      ),

      appBar: AppBar(
        title: Text("Create new ceramic"),

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
                child: Text("Error: ${_controller.error}"),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _controller.load();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageRow(),
                      const SizedBox(height: 25),
                      TitleWidget(title: "PROGRESS"),
                      _buildStageRow(),
                      const SizedBox(height: 25),
                      TitleWidget(title: "INFORMATION"),
                      _buildInformationSection(),
                      const SizedBox(height: 25),
                      TitleWidget(title: "GLAZES"),
                      _buildGlazeSection(),
                      const SizedBox(height: 25),
                      _buildRateRow(),
                      const SizedBox(height: 25),
                      TitleWidget(title: "TAGS"),
                      _buildTagSection(),
                      const SizedBox(height: 25),
                      _buildNoteSection(),
                      const SizedBox(height: 10),
                    ]
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageRow() {
    List<Widget> children = [];

    for (int i = 0; i < 10; i++) {
      children.add(SquareWidget(
          icon: i == 0 ? Icons.camera_alt : Icons.image));
    }
    return SizedBox(
      height: 100,
      child: GridLayout(
        crossAxisCount: 1,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }

  Widget _buildStageRow() {
    return ProgressStepperWidget(
      stages: _controller.stages,
      currentStep: _controller.stage!,
      onChanged: (stage) {
        setState(() {
          _controller.stage = stage;
        });
      },
    );
  }

  Widget _buildInformationSection() {
    return Column(
      children: [
        AdaptiveTextField(
          labelText: "Title",
          maxLines: 1,
          onChanged: (value) async {
            _controller.title = value;
          },
        ),
        const SizedBox(height: 10),
        AdaptiveTextField(
          labelText: "Clay Type",
          maxLines: 1,
          onChanged: (value) async {
            _controller.clayType = value;
          },
        ),
        const SizedBox(height: 10),
        AdaptiveTextField(
          labelText: "Weight",
          keyboardType: TextInputType.number,
          maxLines: 1,
          suffix: "kg",
          onChanged: (value) async {
            _controller.weight = double.tryParse(value) ?? 0.0;
          },
        ),
      ],
    );
  }

  Widget _buildGlazeSection() {
    return GlazeListWidget(
      onUpdate: (index, value) async {
        await _controller.updateGlaze(index, value);
      },
      onAdd: () async {
        await _controller.addGlaze();
      },
      onRemove: (index) async {
        await _controller.removeGlaze(index);
      },
      glazes: [],
    );
  }

  Widget _buildRateRow() {
    return RatingWidget(
      title: "Rate:",
      rating: _controller.rating,
      onChanged: (newRating) {
        setState(() {
          _controller.rating = newRating;
        });
      },
    );
  }

  Widget _buildTagSection() {
    return InlineTagsWidget(
      onAdd: (value) async {
        await _controller.addTag(value);
      },
      onRemove: (index) async {
        await _controller.removeTag(index);
      },
    );
  }

  Widget _buildNoteSection() {
    return AdaptiveTextField(
      labelText: "Notes",
      minLines: 4,
      onChanged: (value) async {
        _controller.notes = value;
      },
    );
  }

  Future<void> _createCeramic() async {
    if (_controller.title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a title")),
      );
      return;
    }

    try {
      await _controller.create();
      if(!context.mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Create failed: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}