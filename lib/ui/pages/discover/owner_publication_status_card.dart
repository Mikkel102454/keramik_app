import 'package:ceramic_app/ui/widgets/feature_gate.dart';
import 'package:ceramic_app/objects/entitlement_dto.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:flutter/material.dart';

class OwnerPublicationStatusCard extends StatelessWidget {
  const OwnerPublicationStatusCard({
    required this.status,
    required this.isFinished,
    required this.hasImage,
    required this.onToggle,
    super.key,
  });

  final PublicationStatusDto status;
  final bool isFinished;
  final bool hasImage;
  final Future<bool> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final moderationRemoved = status.state == 'MODERATION_REMOVED';
    final canPublish = isFinished && hasImage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (moderationRemoved)
              Text(context.l10n.publicationModerationRemoved)
            else if (status.current && !canPublish)
              Text(context.l10n.publicationTemporarilyUnavailable)
            else
              Text(
                status.current
                    ? context.l10n.navigationDiscover
                    : context.l10n.publishFinishedBody,
              ),
            if (!moderationRemoved && (!status.current || !canPublish)) ...[
              const SizedBox(height: 10),
              _requirement(
                context.l10n.publicationFinishedRequirement,
                isFinished,
              ),
              const SizedBox(height: 6),
              _requirement(context.l10n.publicationPhotoRequirement, hasImage),
            ],
            if (status.currentAudience != 'EVERYONE') ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.publicationAudienceFriends,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: moderationRemoved || (!status.current && !canPublish)
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
                        SnackBar(content: Text(context.l10n.operationFailed)),
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

  Widget _requirement(String label, bool met) => Semantics(
    checked: met,
    child: Row(
      children: [
        Icon(
          met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    ),
  );
}
