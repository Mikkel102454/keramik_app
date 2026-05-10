import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/ui/widgets/v2/dropdown_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/glaze_input_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/star_stepper_select_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/stepper_select_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/tag_input_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ceramic_view_page_controller.dart';

class CeramicViewPage extends StatefulWidget {
  final CeramicDto ceramic;
  final List<StageDto> stages;
  final List<ClayDto> clayTypes;
  final List<GlazeDto> glazes;
  const CeramicViewPage({
    super.key,
    required this.ceramic,
    required this.stages,
    required this.clayTypes,
    required this.glazes
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
                child: _pageContent(_controller, widget)
              );
            },
          ),
        ),
      ),
    );
  }

  SingleChildScrollView _pageContent(CeramicViewPageController controller, CeramicViewPage widget) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =========================
          // Images
          // =========================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            physics: const BouncingScrollPhysics(),

            child: Row(
              children: [
                SquareWidget(
                  icon: Icons.image,
                  iconColor: Colors.grey.shade400,
                  iconSize: 42,
                  width: 92,
                  height: 92,
                  backgroundColor: Colors.grey.shade300,
                ),

                const SizedBox(width: 12),

                SquareWidget(
                  icon: Icons.image,
                  iconColor: Colors.grey.shade400,
                  iconSize: 42,
                  width: 92,
                  height: 92,
                  backgroundColor: Colors.grey.shade300,
                ),

                const SizedBox(width: 12),

                SquareWidget(
                  icon: Icons.add,
                  iconColor: Colors.grey.shade500,
                  iconSize: 42,
                  width: 92,
                  height: 92,
                  backgroundColor: Colors.grey.shade300,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // =========================
          // Progress
          // =========================
          TextWidget(
            text: "Progress",
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          StepperSelectWidget(
            initialValue: widget.ceramic.stageId.toString(),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            size: 40,
            entries: [
              for (final stage in widget.stages)
                MapEntry(stage.title, stage.id.toString()),
            ],

            onChanged: (value) async {
              return controller.setStage(int.parse(value));
            },
          ),
          const SizedBox(height: 20),

          // =========================
          // Information
          // =========================
          TextWidget(
            text: "Information",
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: "Title",
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          TextFieldWidget(
            placeholder: "Title",
            initialValue: widget.ceramic.title,
            debounceDuration: Duration(milliseconds: 300),

            onChanged: (value) async {
              return controller.setTitle(value);
            },
          ),

          const SizedBox(height: 12),

          TextWidget(
            text: "Clay Type",
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 4),

          DropdownWidget(
            placeholder: "Select",
            initialValue: widget.ceramic.clayTypeId.toString(),
            entries: [
              for (final clayType in widget.clayTypes)
                MapEntry(clayType.title, clayType.id.toString()),
            ],

            onChanged: (value) async {
              return controller.setClayType(int.parse(value));
            },
          ),

          const SizedBox(height: 12),

          TextWidget(
            text: "Weight",
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 4),

          TextFieldWidget(
            placeholder: "0.0",
            suffix: "kg",
            initialValue: widget.ceramic.weight != 0 ? widget.ceramic.weight.toString() : "",
            debounceDuration: Duration(milliseconds: 300),

            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (value) async {
              return controller.setWeight(value);
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // Glazes
          // =========================
          TextWidget(text: "Glazes", fontSize: 18, fontWeight: FontWeight.w700),
          const SizedBox(height: 8),
          GlazeInputWidget(
            initialValues: [
              for (final glazes in widget.ceramic.glazes)
                GlazeEntry(
                  id: glazes.id,
                  glazeName: widget.glazes.firstWhere((e) => e.id == glazes.glazeId).title,
                  glazeId: glazes.glazeId,
                  notes: glazes.note,
                  expanded: false
                ),
            ],
            glazeEntries: [
              for (final glazes in widget.glazes)
                MapEntry(glazes.title, glazes.id),
            ],
            debounceDuration: Duration(milliseconds: 300),

            onCreate: (glazeId) async {
              return controller.addGlaze(glazeId);
            },
            onDelete: (id) async {
              return controller.removeGlaze(id);
            },
            onNotesChanged: (id, value) async {
              return controller.updateGlaze(id, value);
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // Rating
          // =========================
          TextWidget(text: "Rate", fontSize: 18, fontWeight: FontWeight.w700),
          StarStepperSelectWidget(
            initialValue: widget.ceramic.rating,

            selectedIconColor: Colors.green,

            onChanged: (value) async {
              return controller.setRating(value);
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // Tags
          // =========================
          TextWidget(text: "Tags", fontSize: 18, fontWeight: FontWeight.w700),
          const SizedBox(height: 8),

          TagInputWidget(
            horizontalPadding: 10,
            verticalPadding: 6,

            borderRadius: 5,

            fontSize: 16,
            fontWeight: FontWeight.normal,

            borderColor: Colors.black,
            backgroundColor: Colors.grey.shade300,

            removeIconSize: 20,
            removeIconColor: Colors.red,

            initialValues: [
              for (final tags in widget.ceramic.tags)
                TagEntry(
                  id: tags.id,
                  value: tags.tag,
                ),
            ],
            onCreate: (value) async {
              return controller.addTag(value);
            },
            onRemove: (id) async {
              return controller.removeTag(id);
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // Notes
          // =========================
          TextWidget(text: "Notes", fontSize: 18, fontWeight: FontWeight.w700),
          const SizedBox(height: 8),

          TextFieldWidget(
            placeholder: "Project note",
            initialValue: widget.ceramic.note,
            debounceDuration: Duration(milliseconds: 300),
            minLines: 3,
            maxLines: 5,

            onChanged: (value) async {
              return controller.setNotes(value);
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}