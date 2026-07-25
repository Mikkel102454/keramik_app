import 'dart:io';

import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/objects/ceramic_firing_dto.dart';
import 'package:ceramic_app/objects/ceramic_stage_history_dto.dart';
import 'package:ceramic_app/ui/pages/image_view/image_view_page.dart';
import 'package:ceramic_app/ui/widgets/firing_editor_dialog.dart';
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
import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
    required this.glazes,
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
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Navigator.of(context).pop(_controller.hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.ceramic),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_controller.hasChanged);
            },
          ),

          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(context.l10n.deleteCeramic),
                    content: Text(context.l10n.deleteCeramicQuestion),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(context.l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(context.l10n.delete),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                final success = await _controller.deleteCeramic();

                if (success && context.mounted) {
                  Navigator.of(context).pop(true);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.deleteCeramicFailed)),
                  );
                }
              },
            ),
            IconButton(icon: const Icon(Icons.share), onPressed: () async {}),
          ],
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) {
              if (_controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.error != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.errorWithDetails(
                          '${_controller.error}',
                        ),
                      ),
                      FilledButton(
                        onPressed: () => _controller.load(null, null),
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _controller.load(null, null),
                child: _pageContent(_controller, widget),
              );
            },
          ),
        ),
      ),
    );
  }

  SingleChildScrollView _pageContent(
    CeramicViewPageController controller,
    CeramicViewPage widget,
  ) {
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
                for (final image in controller.ceramic.images) ...[
                  SquareWidget(
                    width: 92,
                    height: 92,
                    imageUri: image.uri,
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black87,
                        builder: (_) => ImageViewPage(
                          image: image,
                          onDelete: () async {
                            final navigator = Navigator.of(context);

                            final success = await controller.deleteImage(image);

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
                  iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  iconSize: 42,
                  width: 92,
                  height: 92,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: Text(context.l10n.selectFromGallery),
                                onTap: () {
                                  Navigator.pop(context, ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: Text(context.l10n.takePicture),
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
            text: context.l10n.progress,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          StepperSelectWidget(
            initialValue: controller.ceramic.stageId.toString(),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            size: 40,
            entries: [
              for (final stage in widget.stages)
                MapEntry(
                  localizedStageName(context.l10n, stage.title),
                  stage.id.toString(),
                ),
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
            text: context.l10n.information,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: context.l10n.title,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          TextFieldWidget(
            placeholder: context.l10n.title,
            initialValue: controller.ceramic.title,
            debounceDuration: Duration(milliseconds: 300),

            onChanged: (value) async {
              if (value == "") return true;
              return controller.setTitle(value);
            },
          ),

          const SizedBox(height: 12),

          TextWidget(
            text: context.l10n.clayType,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),

          DropdownWidget(
            placeholder: context.l10n.select,
            initialValue: controller.ceramic.clayTypeId.toString(),
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
            text: context.l10n.weight,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),

          TextFieldWidget(
            placeholder: "0.0",
            suffix: "kg",
            initialValue: controller.ceramic.weight != 0
                ? controller.ceramic.weight.toString()
                : "",
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

          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              context.l10n.dimensions,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              context.l10n.optionalMeasurementSystem(
                AppSettingsController.instance.measurementSystem
                    .localizedLabel(context.l10n)
                    .toLowerCase(),
              ),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _dimensionField(
                      context.l10n.height,
                      controller.ceramic.heightCm,
                      (value) => controller.setDimension('height', value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dimensionField(
                      context.l10n.width,
                      controller.ceramic.widthCm,
                      (value) => controller.setDimension('width', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dimensionField(
                      context.l10n.depth,
                      controller.ceramic.depthCm,
                      (value) => controller.setDimension('depth', value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dimensionField(
                      context.l10n.diameter,
                      controller.ceramic.diameterCm,
                      (value) => controller.setDimension('diameter', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),

          // =========================
          // Glazes
          // =========================
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              context.l10n.glazeApplications,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: [
              GlazeApplicationEditor(
                entries: controller.ceramic.glazes,
                glazes: widget.glazes,
                onAdd: (glazeId) async =>
                    await controller.addGlaze(glazeId) > 0,
                onDelete: controller.removeGlaze,
                onEdit: controller.updateGlaze,
                onMove: controller.moveGlaze,
              ),
              const SizedBox(height: 12),
            ],
          ),

          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              context.l10n.firings,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              context.l10n.firingRecordCount(controller.firings.length),
            ),
            children: [
              if (controller.firings.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      context.l10n.noFiringRecords,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              for (final firing in controller.firings)
                Card(
                  child: ListTile(
                    title: Text(_firingTypeLabel(context, firing.type)),
                    subtitle: Text(
                      [
                        firing.status == 'PLANNED'
                            ? context.l10n.planned
                            : context.l10n.completed,
                        if (firing.firingDate != null)
                          DateFormat.yMMMd(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(firing.firingDate!),
                        if (firing.targetCone.isNotEmpty)
                          context.l10n.coneValue(firing.targetCone),
                      ].join(' · '),
                    ),
                    onTap: () => _showFiringEditor(firing),
                    trailing: IconButton(
                      tooltip: context.l10n.deleteFiring,
                      onPressed: () => _deleteFiring(firing),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _showFiringEditor(null),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addFiring),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),

          const SizedBox(height: 20),

          // =========================
          // Rating
          // =========================
          TextWidget(
            text: context.l10n.rate,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          StarStepperSelectWidget(
            initialValue: controller.ceramic.rating,

            selectedIconColor: Colors.green,

            onChanged: (value) async {
              return controller.setRating(value);
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // Tags
          // =========================
          TextWidget(
            text: context.l10n.tags,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),

          TagInputWidget(
            horizontalPadding: 10,
            verticalPadding: 6,

            borderRadius: 5,

            fontSize: 16,
            fontWeight: FontWeight.normal,

            borderColor: Theme.of(context).colorScheme.outline,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,

            removeIconSize: 20,
            removeIconColor: Colors.red,

            initialValues: [
              for (final tags in controller.ceramic.tags)
                TagEntry(id: tags.id, value: tags.tag),
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
          TextWidget(
            text: context.l10n.notes,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),

          TextFieldWidget(
            placeholder: context.l10n.projectNotes,
            initialValue: controller.ceramic.note,
            debounceDuration: Duration(milliseconds: 300),
            minLines: 3,
            maxLines: 5,

            onChanged: (value) async {
              return controller.setNotes(value);
            },
          ),

          const SizedBox(height: 10),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              context.l10n.outcome,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: [
              TextFieldWidget(
                placeholder: context.l10n.outcomeHint,
                initialValue: controller.ceramic.outcomeNote,
                debounceDuration: const Duration(milliseconds: 300),
                minLines: 3,
                maxLines: 6,
                onChanged: controller.setOutcomeNote,
              ),
              const SizedBox(height: 12),
            ],
          ),

          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              context.l10n.history,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              controller.ceramic.updatedAt == null
                  ? context.l10n.stageEventCount(
                      controller.stageHistory.length,
                    )
                  : context.l10n.updatedOn(
                      _formatDateTime(
                        context,
                        controller.ceramic.updatedAt!.toLocal(),
                      ),
                    ),
            ),
            children: [
              for (final event in controller.stageHistory)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timeline),
                  title: Text(
                    _historyTitle(context, event),
                  ),
                  subtitle: Text(
                    _formatDateTime(context, event.changedAt.toLocal()),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _dimensionField(
    String label,
    double? value,
    Future<bool> Function(String) onChanged,
  ) {
    final units = AppSettingsController.instance.measurementSystem;
    final displayValue = value == null
        ? null
        : Measurement.lengthFromCentimeters(value, units);
    return TextFieldWidget(
      placeholder: label,
      initialValue: displayValue == null
          ? null
          : Measurement.format(displayValue),
      suffix: units.lengthSymbol,
      debounceDuration: const Duration(milliseconds: 300),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _showFiringEditor(CeramicFiringDto? existing) async {
    await showDialog<void>(
      context: context,
      builder: (_) => FiringEditorDialog(
        ceramicId: _controller.ceramic.id,
        existing: existing,
        onSave: _controller.saveFiring,
      ),
    );
  }

  Future<void> _deleteFiring(CeramicFiringDto firing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteFiringQuestion),
        content: Text(
          context.l10n.deleteFiringExplanation(
            _firingTypeLabel(context, firing.type).toLowerCase(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await _controller.deleteFiring(firing.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.deleteFiringFailed)),
        );
      }
    }
  }

  String _firingTypeLabel(BuildContext context, String type) => switch (type) {
    'BISQUE' => context.l10n.bisqueFiring,
    'GLAZE' => context.l10n.glazeFiring,
    'SINGLE' => context.l10n.singleFiring,
    'OVERGLAZE' => context.l10n.overglazeFiring,
    _ => context.l10n.otherFiring,
  };

  String _historyTitle(
    BuildContext context,
    CeramicStageHistoryDto event,
  ) {
    final toStage = localizedStageName(context.l10n, event.toStageTitle);
    if (event.baseline) return context.l10n.historyStartedAt(toStage);
    final from = event.fromStageTitle;
    if (from == null) return context.l10n.startedAtStage(toStage);
    return context.l10n.stageTransition(
      localizedStageName(context.l10n, from),
      toStage,
    );
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_jm().format(value);
  }
}
