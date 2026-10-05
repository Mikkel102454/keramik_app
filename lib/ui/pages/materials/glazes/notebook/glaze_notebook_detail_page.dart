import 'notebook_labels.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:clay_dock/ui/widgets/v2/ui_library.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/objects/ceramic_dto.dart';
import 'package:clay_dock/objects/glaze_notebook_dto.dart';
import 'package:clay_dock/ui/pages/image_view/image_view_page.dart';
import 'package:clay_dock/app/app_settings_controller.dart';
import 'package:clay_dock/utils/measurement.dart';
import 'glaze_notebook_controller.dart';
import 'glaze_notebook_editor_page.dart';
import 'package:clay_dock/app/combination_application_controller.dart';
import 'combination_application_dialog.dart';

class GlazeNotebookDetailPage extends StatefulWidget {
  const GlazeNotebookDetailPage({
    super.key,
    required this.value,
    required this.controller,
  });
  final GlazeNotebookDto value;
  final GlazeNotebookController controller;
  @override
  State<GlazeNotebookDetailPage> createState() =>
      _GlazeNotebookDetailPageState();
}

class _GlazeNotebookDetailPageState extends State<GlazeNotebookDetailPage> {
  late GlazeNotebookDto value;
  late CombinationApplicationController application;
  bool busy = false;
  String? error;
  bool get tiles => widget.controller.repository.tiles;
  @override
  void initState() {
    super.initState();
    value = widget.value;
    application =
        CombinationApplicationController.forRecipe(value.id) ??
        CombinationApplicationController();
  }

  Future<void> reload() async {
    final fresh = await widget.controller.detail(value.id);
    if (mounted) {
      setState(() {
        if (fresh != null) value = fresh;
        error = fresh == null ? context.l10n.notebookFailed : null;
      });
    }
  }

  Future<void> edit() async {
    final saved = await Navigator.push<GlazeNotebookDto>(
      context,
      MaterialPageRoute(
        builder: (_) => GlazeNotebookEditorPage(
          controller: widget.controller,
          value: value,
        ),
      ),
    );
    if (saved != null && mounted) setState(() => value = saved);
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(context.l10n.notebookDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    final ok = await widget.controller.delete(value);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        busy = false;
        error = widget.controller.conflict
            ? context.l10n.notebookConflict
            : context.l10n.notebookFailed;
      });
    }
  }

  Future<void> createTile() async {
    final controller = GlazeNotebookController(tiles: true);
    controller.clays = widget.controller.clays;
    controller.glazes = widget.controller.glazes;
    try {
      final saved = await Navigator.push<GlazeNotebookDto>(
        context,
        MaterialPageRoute(
          builder: (_) => GlazeNotebookEditorPage(
            controller: controller,
            value: value.tileDraft(),
          ),
        ),
      );
      if (saved != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GlazeNotebookDetailPage(value: saved, controller: controller),
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> confirmDeletePhoto(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(context.l10n.deleteImageQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await photo(id);
  }

  Future<void> photo([int? imageId]) async {
    if (busy) return;
    XFile? picked;
    if (imageId == null) {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final fresh = imageId == null
        ? await widget.controller.upload(value.id, File(picked!.path))
        : await widget.controller.deleteImage(value.id, imageId);
    if (mounted) {
      setState(() {
        busy = false;
        if (fresh != null) {
          value = fresh;
        } else {
          error = context.l10n.notebookPhotoFailed;
        }
      });
    }
  }

  Future<void> apply() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      CeramicDto? piece;
      if (application.pendingPieceId != null) {
        piece = await application.piece(application.pendingPieceId!);
      } else {
        final pieces = await application.pieces();
        if (!mounted) return;
        piece = await showDialog<CeramicDto>(
          context: context,
          builder: (c) => SimpleDialog(
            title: Text(context.l10n.applySavedCombination),
            children: [
              if (pieces.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.l10n.notebookEmpty),
                ),
              for (final p in pieces)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(c, p),
                  child: Text(p.title),
                ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(c),
                child: Text(context.l10n.cancel),
              ),
            ],
          ),
        );
        if (piece != null) piece = await application.piece(piece.id);
      }
      if (piece == null || !mounted) return;
      final selected = piece;
      application = CombinationApplicationController.forPiece(selected.id);
      await previewCombination(
        context,
        recipe: application.pending ?? value,
        existing: selected.glazes,
        glazes: widget.controller.glazes,
        application: application,
        onApply: () async {
          application.begin(value, selected.id);
          return application.apply(() async {
            await application.piece(selected.id);
          });
        },
      );
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.notebookFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String temperature(double? c) {
    if (c == null) return '';
    final units = AppSettingsController.instance.measurementSystem;
    return '${Measurement.format(Measurement.temperatureFromCelsius(c, units))}${units.temperatureSymbol}';
  }

  Widget layers(GlazeNotebookDto n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < n.layers.length; i++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${i + 1}. ${n.layers[i].glazeTitle}'),
          subtitle: Text(
            '${context.l10n.coatCount(n.layers[i].coatCount)} · ${n.layers[i].note}',
          ),
          trailing: n.layers[i].glazeId == null
              ? Tooltip(
                  message: context.l10n.replaceUnavailableGlaze,
                  child: const Icon(Icons.warning_amber),
                )
              : null,
        ),
    ],
  );
  Widget firings(GlazeNotebookDto n) => Column(
    children: [
      for (var i = 0; i < n.firings.length; i++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '${i + 1}. ${notebookFiringType(context, n.firings[i].firing.type)} · ${notebookFiringStatus(context, n.firings[i].firing.status)}',
          ),
          subtitle: Text(
            [
              if (n.firings[i].atmosphere != null)
                notebookAtmosphere(context, n.firings[i].atmosphere!),
              if (n.firings[i].firing.firingDate != null)
                '${n.firings[i].firing.firingDate!.toLocal()}'.split(' ').first,
              n.firings[i].firing.targetCone,
              temperature(n.firings[i].firing.targetTemperatureC),
              n.firings[i].firing.observedCone,
              temperature(n.firings[i].firing.peakTemperatureC),
              n.firings[i].firing.kiln,
              n.firings[i].firing.program,
              n.firings[i].firing.note,
            ].where((s) => s.isNotEmpty).join(' · '),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => EntryPage(
    title: value.name,
    onEdit: edit,
    onDelete: delete,
    onRefresh: reload,
    onRetry: reload,
    busy: busy,
    error: error,
    children: [
      EntrySection(
        title: context.l10n.information,
        children: [
          EntryValue(label: context.l10n.notebookName, value: value.name),
          EntryValue(label: context.l10n.projectNotes, value: value.notes),
          if (value.clayTitle != null)
            EntryValue(label: context.l10n.clay, value: value.clayTitle!),
          if (value.sourceName != null)
            EntryValue(
              label: context.l10n.sourceRecipe,
              value: '${value.sourceName} ? v${value.sourceVersion}',
            ),
        ],
      ),
      EntrySection(
        title: context.l10n.glazeApplications,
        children: [layers(value)],
      ),
      EntrySection(
        title: tiles ? context.l10n.firings : context.l10n.plannedFirings,
        children: [
          value.firings.isEmpty ? Text(context.l10n.notSet) : firings(value),
        ],
      ),
      if (!tiles) ...[
        FilledButton.icon(
          onPressed: createTile,
          icon: const Icon(Icons.science_outlined),
          label: Text(context.l10n.createTestTile),
        ),
        TextButton.icon(
          onPressed: apply,
          icon: const Icon(Icons.layers_outlined),
          label: Text(context.l10n.applySavedCombination),
        ),
      ],
      if (tiles) ...[
        EntrySection(
          title: context.l10n.resultNotes,
          children: [
            EntryValue(label: context.l10n.notes, value: value.resultNotes),
          ],
        ),
        if (value.originalRecipe != null)
          ExpansionTile(
            title: Text(context.l10n.sourceRecipeSnapshot),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              EntrySection(
                title: context.l10n.information,
                children: [
                  EntryValue(
                    label: context.l10n.notebookName,
                    value: value.originalRecipe!.name,
                  ),
                  EntryValue(
                    label: context.l10n.projectNotes,
                    value: value.originalRecipe!.notes,
                  ),
                  if (value.originalRecipe!.clayTitle != null)
                    EntryValue(
                      label: context.l10n.clay,
                      value: value.originalRecipe!.clayTitle!,
                    ),
                ],
              ),
              layers(value.originalRecipe!),
              firings(value.originalRecipe!),
            ],
          ),
        const SizedBox(height: 20),
        EntrySection(
          title: context.l10n.notebookPhotos,
          children: [
            for (final image in value.images)
              Card(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewPage(
                            image: image,
                            onDelete: () => photo(image.id),
                          ),
                        ),
                      ),
                      child: Image.network(
                        image.uri,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 80,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => confirmDeletePhoto(image.id),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(context.l10n.delete),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: value.images.length >= 20 ? null : () => photo(),
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(context.l10n.add),
            ),
          ],
        ),
      ],
    ],
  );
}
