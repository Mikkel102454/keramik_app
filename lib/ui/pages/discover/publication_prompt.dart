import 'package:ceramic_app/ui/widgets/feature_gate.dart';
import 'package:ceramic_app/objects/entitlement_dto.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

Future<bool> showFinishedPublicationPrompt(
  BuildContext context, {
  required bool hasImage,
}) async {
  final publish = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        hasImage
            ? context.l10n.publishFinishedTitle
            : context.l10n.publicationPhotoRequiredTitle,
      ),
      content: Text(
        hasImage
            ? context.l10n.publishFinishedBody
            : context.l10n.publicationPhotoRequiredBody,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.notNowAction),
        ),
        if (hasImage)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.publishAction),
          ),
      ],
    ),
  );
  if (publish != true || !context.mounted) return false;
  return requireFeature(context, Features.publishedPieces);
}
