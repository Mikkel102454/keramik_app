import 'package:clay_dock/objects/ceramic_dto.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';
import 'ceramic_preview_tile.dart';

class CeramicJournalCard extends StatelessWidget {
  const CeramicJournalCard({
    super.key,
    required this.ceramic,
    required this.stageTitle,
    required this.clayTitle,
    required this.onTap,
  }) : publicTitle = null,
       publicRating = null,
       publicImageUrl = null;

  const CeramicJournalCard.public({
    super.key,
    required this.publicTitle,
    required this.publicRating,
    required this.publicImageUrl,
    required this.stageTitle,
    required this.clayTitle,
    this.onTap,
  }) : ceramic = null;

  final CeramicDto? ceramic;
  final String? publicTitle;
  final int? publicRating;
  final String? publicImageUrl;
  final String stageTitle;
  final String? clayTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currentCeramic = ceramic;
    final image = currentCeramic == null
        ? publicImageUrl
        : currentCeramic.images.isEmpty
        ? null
        : currentCeramic.images.first.uri;
    final title = currentCeramic?.title ?? publicTitle ?? '';
    final rating = currentCeramic?.rating ?? publicRating ?? 0;
    return CeramicPreviewTile(
      title: title,
      imageUrl: image,
      subtitle: clayTitle,
      stageTitle: stageTitle,
      rating: rating,
      onTap: onTap,
      semanticLabel: [
        title,
        if (clayTitle?.isNotEmpty == true) clayTitle!,
        stageTitle,
        '${context.l10n.rating}: $rating',
      ].join(', '),
    );
  }
}
