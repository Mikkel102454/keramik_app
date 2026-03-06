import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/ui/widgets/GridLayout.dart';
import 'package:ceramic_app/ui/widgets/SquareWidget.dart';
import 'package:ceramic_app/ui/widgets/adaptive/adaptive_text_field.dart';
import '../widget/GlazeListWidget.dart';
import '../widget/InlineTagsWidget.dart';
import '../widget/ProgressStepperWidget.dart';
import '../widget/RatingWidget.dart';
import '../widget/TitleWidget.dart';
import 'ceramic_view_page_controller.dart';

@RoutePage()
class CeramicViewPage extends StatefulWidget {
  final CeramicDto ceramic;
  final List<StageDto> stages;
  const CeramicViewPage({
    super.key,
    required this.ceramic,
    required this.stages,
  });

  @override
  State<CeramicViewPage> createState() => _CeramicViewPageState();
}

class _CeramicViewPageState extends State<CeramicViewPage> {
  final CeramicViewPageController _controller = CeramicViewPageController();

  @override
  void initState() {
    super.initState();
    _controller.load(widget.ceramic, widget.stages);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        Navigator.of(context).pop(_controller.hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ceramic View"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_controller.hasChanged);
            },
          ),
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
                  _controller.load(null, null);
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
      currentStep: _controller.stage,
      onChanged: (stage) {
        _controller.setStage(stage);
      },
    );
  }

  Widget _buildInformationSection() {
    return Column(
      children: [
        AdaptiveTextField(
          labelText: "Title",
          maxLines: 1,
          debounceDuration: Duration(milliseconds: 500),
          initialValue: _controller.ceramic.title,
          onChanged: (value) async {
            await _controller.setTitle(value);
          },
        ),
        const SizedBox(height: 10),
        AdaptiveTextField(
          labelText: "Clay Type",
          maxLines: 1,
          debounceDuration: Duration(milliseconds: 500),
          initialValue: _controller.ceramic.type,
          onChanged: (value) async {
            await _controller.setClayType(value);
          },
        ),
        const SizedBox(height: 10),
        AdaptiveTextField(
          labelText: "Weight",
          keyboardType: TextInputType.number,
          maxLines: 1,
          debounceDuration: Duration(milliseconds: 500),
          initialValue: _controller.ceramic.weight.toString(),
          suffix: "kg",
          onChanged: (value) async {
            await _controller.setWeight(double.tryParse(value) ?? 0.0);
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
      glazes: _controller.glazes.map((glaze) => glaze.note).toList(),
    );
  }

  Widget _buildRateRow() {
    return RatingWidget(
      title: "Rate:",
      rating: _controller.ceramic.rate,
      onChanged: (newRating) async {
        await _controller.setRating(newRating);
      },
    );
  }

  Widget _buildTagSection() {
    return InlineTagsWidget(
      initialTags: _controller.tags.map((tag) => tag.tag).toList(),
      onAdd: (value) async {
        await _controller.addTag(value);
      },
      onRemove: (index) async {
        await _controller.removeTag(index);
      },
      onUpdate: (index, value) async {
        await _controller.updateTag(index, value);
      },
    );
  }

  Widget _buildNoteSection() {
    return AdaptiveTextField(
      labelText: "Notes",
      minLines: 4,
      debounceDuration: Duration(milliseconds: 500),
      initialValue: _controller.ceramic.note,
      onChanged: (value) async {
        await _controller.setNotes(value);
      },
    );
  }
}