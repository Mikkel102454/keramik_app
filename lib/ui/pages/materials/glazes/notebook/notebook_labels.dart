import 'package:flutter/widgets.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';

String notebookFiringType(BuildContext context, String type) => switch (type) {
  'BISQUE' => context.l10n.firingBisque,
  'GLAZE' => context.l10n.firingGlaze,
  'SINGLE' => context.l10n.firingSingle,
  'OVERGLAZE' => context.l10n.firingOverglaze,
  _ => context.l10n.other,
};
String notebookFiringStatus(BuildContext context, String status) =>
    status == 'COMPLETED' ? context.l10n.completed : context.l10n.planned;
String notebookAtmosphere(BuildContext context, String atmosphere) =>
    switch (atmosphere) {
      'OXIDATION' => context.l10n.atmosphereOxidation,
      'REDUCTION' => context.l10n.atmosphereReduction,
      'NEUTRAL' => context.l10n.atmosphereNeutral,
      _ => context.l10n.other,
    };
