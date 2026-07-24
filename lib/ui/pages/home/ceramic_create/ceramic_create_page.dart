import 'dart:io';

import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/ui/pages/image_view/image_view_page.dart';
import 'package:ceramic_app/ui/widgets/v2/dropdown_widget.dart';
import 'package:ceramic_app/ui/widgets/glaze_application_editor.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/star_stepper_select_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/stepper_select_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/tag_input_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'ceramic_create_page_controller.dart';

class CeramicCreatePage extends StatefulWidget {
  final List<StageDto> stages;
  final List<ClayDto> clayTypes;
  final List<GlazeDto> glazes;

  const CeramicCreatePage({
    super.key,
    required this.stages,
    required this.clayTypes,
    required this.glazes
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
      appBar: AppBar(
        title: Text("Ceramic"),

        actions: [IconButton(icon: const Icon(Icons.check), onPressed: () {_createCeramic();})],
      ),

      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.error != null) {
              return Center(child: Text("Error: ${_controller.error}"));
            }

            return RefreshIndicator(
              onRefresh: () async {
                _controller.load();
              },
              child: _pageContent(_controller, widget),
            );
          },
        ),
      ),
    );
  }

  SingleChildScrollView _pageContent(CeramicCreatePageController controller, CeramicCreatePage widget) {
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
                for (final entry in controller.images.asMap().entries) ...[
                SquareWidget(
                width: 92,
                  height: 92,
                  imageFile: entry.value,
                  onPressed: () async {

                    showDialog(
                      context: context,
                      barrierColor: Colors.black87,
                      builder: (_) => ImageViewPage(
                        xFile: entry.value,
                        onDelete: () async {
                          final navigator = Navigator.of(context);

                          final success =
                          await controller.deleteImage(
                            entry.key,
                          );

                          if (success) {
                            navigator.pop();
                          }
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(width: 12),
                ],

                SquareWidget(
                  icon: Icons.add,
                  iconColor: Colors.grey.shade500,
                  iconSize: 42,
                  width: 92,
                  height: 92,
                  backgroundColor: Colors.grey.shade300,
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Select from gallery'),
                                onTap: () {
                                  Navigator.pop(context, ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Take a picture'),
                                onTap: () {
                                  Navigator.pop(context, ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (source == null) return;

                    final picked = await ImagePicker().pickImage(
                      source: source,
                    );

                    if (picked != null) {
                      controller.uploadImage(File(picked.path));
                    }
                  },
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
            initialValue: "1",
            fontSize: 12,
            fontWeight: FontWeight.w600,
            size: 40,
            entries: [
              for (final stage in widget.stages)
                MapEntry(stage.title, stage.id.toString()),
            ],

            onChanged: (value) async {
              controller.setStage(int.parse(value));
              return true;
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
            onChanged: (value) async {
              controller.setTitle(value);
              return true;
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

            entries: [
              for (final clayType in widget.clayTypes)
                MapEntry(clayType.title, clayType.id.toString()),
            ],

            onChanged: (value) async {
              controller.setClayType(int.parse(value));
              return true;
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (value) async {
              controller.setWeight(value);
              return true;
            },
          ),

          const SizedBox(height: 20),

          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Dimensions', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Optional · centimeters'),
            children: [
              Row(children: [
                Expanded(child: _dimensionField('Height', (value) => controller.setDimension('height', value))),
                const SizedBox(width: 10),
                Expanded(child: _dimensionField('Width', (value) => controller.setDimension('width', value))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _dimensionField('Depth', (value) => controller.setDimension('depth', value))),
                const SizedBox(width: 10),
                Expanded(child: _dimensionField('Diameter', (value) => controller.setDimension('diameter', value))),
              ]),
              const SizedBox(height: 12),
            ],
          ),

          // =========================
          // Glazes
          // =========================
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Glaze applications', style: TextStyle(fontWeight: FontWeight.w700)),
            children: [
              GlazeApplicationEditor(
                entries: controller.glazes,
                glazes: widget.glazes,
                onAdd: (glazeId) async => await controller.addGlaze(glazeId) > 0,
                onDelete: (id) async {
                  await controller.removeGlaze(id);
                  return true;
                },
                onEdit: controller.updateGlaze,
                onMove: controller.moveGlaze,
              ),
              const SizedBox(height: 12),
            ],
          ),

          const SizedBox(height: 20),

          // =========================
          // Rating
          // =========================
          TextWidget(text: "Rate", fontSize: 18, fontWeight: FontWeight.w700),
          StarStepperSelectWidget(
            initialValue: 0,

            selectedIconColor: Colors.green,

            onChanged: (value) async {
              controller.setRating(value);
              return true;
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

            onCreate: (value) async {
              return controller.addTag(value);
            },
            onRemove: (id) async {
              controller.removeTag(id);
              return true;
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // Notes
          // =========================
          TextWidget(text: "Notes", fontSize: 18, fontWeight: FontWeight.w700),
          const SizedBox(height: 8),

          TextFieldWidget(
            placeholder: "Project notes",

            minLines: 3,
            maxLines: 5,

            onChanged: (value) async {
              controller.setNotes(value);
              return true;
            },
          ),

          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Outcome', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Optional result notes'),
            children: [
              TextFieldWidget(
                placeholder: 'How did the piece turn out?',
                minLines: 3,
                maxLines: 6,
                onChanged: (value) async {
                  controller.setOutcomeNote(value);
                  return true;
                },
              ),
              const SizedBox(height: 12),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _createCeramic() async {
    if (_controller.title.trim().isEmpty || _controller.title.length > 255) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a title up to 255 characters")));
      return;
    }
    if (_controller.stageId <= 0 || _controller.clayTypeId < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid stage selected")));
      return;
    }
    if (_controller.rating < 0 || _controller.rating > 5 ||
        _controller.weight < 0 || _controller.notes.length > 255 ||
        _controller.outcomeNote.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Check rating, weight, and note lengths before saving.'),
      ));
      return;
    }

    try {
      await _controller.create();
      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Create failed: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _dimensionField(String label, ValueChanged<String> onChanged) {
    return TextFieldWidget(
      placeholder: label,
      suffix: 'cm',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (value) async {
        onChanged(value);
        return true;
      },
    );
  }
}
