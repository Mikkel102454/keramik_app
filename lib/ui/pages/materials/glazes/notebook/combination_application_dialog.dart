import 'package:flutter/material.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/objects/ceramic_glaze_entry_dto.dart';
import 'package:clay_dock/objects/glaze_dto.dart';
import 'package:clay_dock/objects/glaze_notebook_dto.dart';
import 'package:clay_dock/objects/entitlement_dto.dart';
import 'package:clay_dock/ui/widgets/feature_gate.dart';
import 'package:clay_dock/app/combination_application_controller.dart';
import 'glaze_notebook_page.dart';

Future<GlazeNotebookDto?> selectCombination(BuildContext context) =>
    Navigator.push<GlazeNotebookDto>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const GlazeNotebookPage(tiles: false, selectRecipe: true),
      ),
    );

Future<bool> previewCombination(
  BuildContext context, {
  required GlazeNotebookDto recipe,
  required List<CeramicGlazeEntryDto> existing,
  required List<GlazeDto> glazes,
  required Future<bool> Function() onApply,
  CombinationApplicationController? application,
}) async {
  if (recipe.layers.any((l) => l.glazeId == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.replaceUnavailableGlaze)),
    );
    return false;
  }
  final ordered = [...existing]
    ..sort((a, b) => a.layerOrder.compareTo(b.layerOrder));
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool busy = false;
          String? error;
          return StatefulBuilder(
            builder: (c, setState) => PopScope(
              canPop: !busy,
              child: AlertDialog(
                title: Text(context.l10n.appendCombinationPreview),
                content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${recipe.name} · v${recipe.version}'),
                        Text(context.l10n.appendCombinationHelp),
                        const SizedBox(height: 12),
                        for (var i = 0; i < ordered.length; i++)
                          Text(
                            '${i + 1}. '
                            '${glazes.where((g) => g.id == ordered[i].glazeId).map((g) => g.title).firstOrNull ?? context.l10n.unknownGlaze}'
                            ' · ${context.l10n.coatCount(ordered[i].coatCount)}${ordered[i].note.isEmpty ? '' : ' · ${ordered[i].note}'}',
                          ),
                        const Divider(),
                        for (var i = 0; i < recipe.layers.length; i++)
                          Text(
                            '${ordered.length + i + 1}. '
                            '${recipe.layers[i].glazeTitle} · ${context.l10n.coatCount(recipe.layers[i].coatCount)}'
                            '${recipe.layers[i].note.isEmpty ? '' : ' · ${recipe.layers[i].note}'}',
                          ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: busy ? null : () => Navigator.pop(c, false),
                    child: Text(context.l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (application?.pending == null &&
                                recipe.layers.any((l) => l.coatCount != 1) &&
                                !await requireFeature(
                                  c,
                                  Features.customGlazeCoats,
                                )) {
                              return;
                            }
                            if (!c.mounted) return;
                            setState(() {
                              busy = true;
                              error = null;
                            });
                            final success = await onApply();
                            if (!c.mounted) return;
                            if (success) {
                              Navigator.pop(c, true);
                            } else {
                              setState(() {
                                busy = false;
                                error = application?.conflict == true
                                    ? context.l10n.combinationApplyConflict
                                    : context.l10n.combinationApplyUncertain;
                              });
                            }
                          },
                    child: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            error == null
                                ? context.l10n.applySavedCombination
                                : context.l10n.retry,
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ) ??
      false;
}
