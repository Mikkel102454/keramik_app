import 'package:ceramic_app/ui/widgets/feature_gate.dart';
import 'package:ceramic_app/objects/entitlement_dto.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:flutter/material.dart';

class OwnerPublicationStatusCard extends StatelessWidget {
  const OwnerPublicationStatusCard({
    required this.status,
    required this.onToggle,
    super.key,
  });

  final PublicationStatusDto status;
  final Future<bool> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final moderationRemoved = status.state == 'MODERATION_REMOVED';
    final audience = status.currentAudience == 'EVERYONE'
        ? context.l10n.publicationAudienceEveryone
        : context.l10n.publicationAudienceFriends;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (moderationRemoved)
              Text(context.l10n.publicationModerationRemoved)
            else if (status.current && !status.eligible)
              Text(context.l10n.publicationTemporarilyUnavailable)
            else
              Text(
                status.current
                    ? context.l10n.navigationDiscover
                    : context.l10n.publishFinishedBody,
              ),
            const SizedBox(height: 8),
            Text(audience, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: moderationRemoved
                  ? null
                  : () async {
                      if (!status.current &&
                          (!await requireFeature(
                                context,
                                Features.publishedPieces,
                              ) ||
                              !context.mounted)) {
                        return;
                      }
                      if (await onToggle() || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.tryAgain)),
                      );
                    },
              icon: Icon(status.current ? Icons.visibility_off : Icons.public),
              label: Text(
                status.current
                    ? context.l10n.unpublishAction
                    : context.l10n.publishAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
