import 'package:flutter/material.dart';
import 'package:ceramic_app/ui/widgets/v2/ui_library.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/glaze_notebook_dto.dart';
import 'package:ceramic_app/ui/widgets/glaze_application_editor.dart';
import 'package:ceramic_app/ui/widgets/firing_editor_dialog.dart';
import 'glaze_notebook_controller.dart';
import 'package:ceramic_app/objects/entitlement_dto.dart';
import 'package:ceramic_app/ui/widgets/feature_gate.dart';
import 'notebook_labels.dart';

class GlazeNotebookEditorPage extends StatefulWidget {
  const GlazeNotebookEditorPage({
    super.key,
    required this.controller,
    this.value,
  });
  final GlazeNotebookController controller;
  final GlazeNotebookDto? value;
  @override
  State<GlazeNotebookEditorPage> createState() =>
      _GlazeNotebookEditorPageState();
}

class _GlazeNotebookEditorPageState extends State<GlazeNotebookEditorPage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, notes, results;
  late final GlazeNotebookDto draft;
  final Map<NotebookLayerDto, int> localIds = {};
  int nextId = 1;
  bool saving = false, dirty = false, leaving = false;
  String? error;
  bool get tiles => widget.controller.repository.tiles;
  @override
  void initState() {
    super.initState();
    final value = widget.value;
    draft = value == null
        ? GlazeNotebookDto(name: '', layers: [], firings: [])
        : GlazeNotebookDto.fromJson({
            'id': value.id,
            'version': value.version,
            ...value.toRequestJson(),
            'sourceName': value.sourceName,
            'sourceVersion': value.sourceVersion,
            'sourceSnapshot': value.sourceSnapshot,
            'clayTitle': value.clayTitle,
          });
    for (final l in draft.layers) {
      localIds[l] = nextId++;
    }
    name = TextEditingController(text: draft.name);
    notes = TextEditingController(text: draft.notes);
    results = TextEditingController(text: draft.resultNotes);
    for (final c in [name, notes, results]) {
      c.addListener(() {
        if (mounted &&
            !dirty &&
            (name.text != draft.name ||
                notes.text != draft.notes ||
                results.text != draft.resultNotes)) {
          setState(() => dirty = true);
        }
      });
    }
  }

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    results.dispose();
    super.dispose();
  }

  void change(VoidCallback fn) {
    setState(() {
      fn();
      dirty = true;
    });
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    final oldCounts = {
      for (final l in widget.value?.layers ?? <NotebookLayerDto>[])
        l.id: l.coatCount,
    };
    final needsCoats = draft.layers.any(
      (l) => draft.id == 0 || l.id == null
          ? l.coatCount != 1
          : oldCounts[l.id] != l.coatCount,
    );
    if (needsCoats &&
        !await requireFeature(context, Features.customGlazeCoats)) {
      return;
    }
    if (!mounted) return;
    if (draft.layers.isEmpty ||
        draft.layers.length > 20 ||
        draft.layers.any((l) => l.coatCount < 1 || l.coatCount > 20)) {
      setState(() => error = context.l10n.notebookLayerLimit);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    draft.name = name.text.trim();
    draft.notes = notes.text;
    draft.resultNotes = results.text;
    final saved = await widget.controller.save(draft);
    if (!mounted) return;
    if (saved != null) {
      setState(() {
        leaving = true;
        dirty = false;
        saving = false;
      });
      Navigator.pop(context, saved);
    } else {
      setState(() {
        saving = false;
        error = widget.controller.conflict
            ? context.l10n.notebookConflict
            : context.l10n.notebookFailed;
      });
    }
  }

  Future<void> editFiring([int? index]) async {
    String? atmosphere = index == null ? null : draft.firings[index].atmosphere;
    await showDialog<void>(
      context: context,
      builder: (_) => FiringEditorDialog(
        ceramicId: 0,
        existing: index == null ? null : draft.firings[index].firing,
        planningOnly: !tiles,
        showAtmosphere: true,
        initialAtmosphere: atmosphere,
        onAtmosphere: (v) => atmosphere = v,
        onSave: (f) async {
          change(() {
            final value = NotebookFiringDto(
              id: index == null ? null : draft.firings[index].id,
              firing: f,
              atmosphere: atmosphere,
            );
            if (index == null) {
              draft.firings.add(value);
            } else {
              draft.firings[index] = value;
            }
          });
          return true;
        },
      ),
    );
  }

  Future<void> leave() async {
    if (!dirty) {
      setState(() => leaving = true);
      Navigator.pop(context);
      return;
    }
    final discard = await confirmEntryDiscard(context);
    if (discard == true && mounted) {
      setState(() => leaving = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving || (!dirty && !saving),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !saving) leave();
    },
    child: Form(
      key: form,
      child: EntryPage(
        title: tiles
            ? (draft.id == 0
                  ? context.l10n.createTestTile
                  : context.l10n.editTestTile)
            : (draft.id == 0
                  ? context.l10n.createCombination
                  : context.l10n.editCombination),
        onSave: save,
        busy: saving,
        error: error,
        children: [
          EntrySection(
            title: context.l10n.information,
            children: [
              if (draft.sourceName != null)
                EntryValue(
                  label: context.l10n.sourceRecipe,
                  value: '${draft.sourceName} ? v${draft.sourceVersion}',
                ),
              TextFieldWidget(
                controller: name,
                label: context.l10n.notebookName,
                maxLength: 100,
                validator: (v, _) => v == null || v.trim().isEmpty
                    ? context.l10n.requiredField
                    : null,
              ),
              TextFieldWidget(
                controller: notes,
                label: context.l10n.projectNotes,
                maxLength: 2000,
                minLines: 2,
                maxLines: 5,
              ),
            ],
          ),
          EntrySection(
            title: tiles
                ? context.l10n.actualConditions
                : context.l10n.recipeDefaults,
            children: [
              SelectFieldWidget<int>(
                label: context.l10n.clay,
                value: draft.clayId,
                items: [
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text(
                      draft.clayId == null && draft.clayTitle != null
                          ? '${draft.clayTitle} (${context.l10n.notSet})'
                          : context.l10n.noClay,
                    ),
                  ),
                  ...widget.controller.clays.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.title)),
                  ),
                ],
                onChanged: (v) => change(() => draft.clayId = v),
              ),
            ],
          ),
          EntrySection(
            title: context.l10n.glazeApplications,
            children: [
              GlazeApplicationEditor(
                entries: [
                  for (var i = 0; i < draft.layers.length; i++)
                    draft.layers[i].entry(localIds[draft.layers[i]]!, i + 1),
                ],
                glazes: widget.controller.glazes,
                maxLayers: 20,
                glazeNames: {
                  for (final l in draft.layers) l.glazeId ?? 0: l.glazeTitle,
                },
                entryNames: {
                  for (final l in draft.layers) localIds[l]!: l.glazeTitle,
                },
                onAdd: (id) async {
                  if (draft.layers.length >= 20) return false;
                  change(() {
                    final layer = NotebookLayerDto(
                      glazeId: id,
                      glazeTitle: widget.controller.glazes
                          .firstWhere((g) => g.id == id)
                          .title,
                    );
                    draft.layers.add(layer);
                    localIds[layer] = nextId++;
                  });
                  return true;
                },
                onEdit: (id, note, coats) async {
                  change(() {
                    final l = draft.layers.firstWhere((l) => localIds[l] == id);
                    l.note = note;
                    l.coatCount = coats;
                  });
                  return true;
                },
                onDelete: (id) async {
                  change(
                    () => draft.layers.removeWhere((l) => localIds[l] == id),
                  );
                  return true;
                },
                onMove: (id, direction) async {
                  final index = draft.layers.indexWhere(
                    (l) => localIds[l] == id,
                  );
                  if (index + direction < 0 ||
                      index + direction >= draft.layers.length) {
                    return false;
                  }
                  change(() {
                    final l = draft.layers.removeAt(index);
                    draft.layers.insert(index + direction, l);
                  });
                  return true;
                },
              ),
            ],
          ),
          EntrySection(
            title: tiles ? context.l10n.firings : context.l10n.plannedFirings,
            children: [
              for (var i = 0; i < draft.firings.length; i++)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          '${i + 1}. ${notebookFiringType(context, draft.firings[i].firing.type)}',
                        ),
                        subtitle: Text(
                          '${notebookFiringStatus(context, draft.firings[i].firing.status)} · ${draft.firings[i].firing.targetCone}',
                        ),
                        onTap: () => editFiring(i),
                      ),
                      Wrap(
                        children: [
                          IconButton(
                            tooltip: context.l10n.moveUp,
                            onPressed: i == 0
                                ? null
                                : () => change(() {
                                    final f = draft.firings.removeAt(i);
                                    draft.firings.insert(i - 1, f);
                                  }),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            tooltip: context.l10n.moveDown,
                            onPressed: i == draft.firings.length - 1
                                ? null
                                : () => change(() {
                                    final f = draft.firings.removeAt(i);
                                    draft.firings.insert(i + 1, f);
                                  }),
                            icon: const Icon(Icons.arrow_downward),
                          ),
                          IconButton(
                            tooltip: context.l10n.delete,
                            onPressed: () =>
                                change(() => draft.firings.removeAt(i)),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: draft.firings.length >= 20
                    ? null
                    : () => editFiring(),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addFiring),
              ),
            ],
          ),
          if (tiles)
            EntrySection(
              title: context.l10n.resultNotes,
              children: [
                TextFieldWidget(
                  controller: results,
                  semanticsLabel: context.l10n.resultNotes,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 6,
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
