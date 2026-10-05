import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';
import 'package:flutter/material.dart';

/// Shared photo proportions and gutters for journal and profile previews.
abstract final class CeramicPreviewGrid {
  static const double maxWidth = StudioSpacing.contentWidth;

  static SliverGridDelegateWithFixedCrossAxisCount delegate(
    double width,
    TextScaler textScaler,
  ) {
    final columns = width < 220
        ? 1
        : width < 330
        ? 2
        : width < 600
        ? 3
        : width < 750
        ? 4
        : width < 1000
        ? 5
        : 6;
    final tileWidth = (width - (columns - 1) * 2) / columns;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: 2,
      mainAxisSpacing: 2,
      mainAxisExtent: tileWidth * 1.3 + 30 * textScaler.scale(14) / 14,
    );
  }
}

/// Tight image tiles retain their full accessible title and detail navigation.
class CeramicPreviewTile extends StatelessWidget {
  const CeramicPreviewTile({
    super.key,
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.stageTitle,
    this.rating,
    required this.onTap,
    this.likeCount = 0,
    this.semanticLabel,
  });
  final String title;
  final String? imageUrl, subtitle, stageTitle;
  final int? rating;
  final VoidCallback? onTap;
  final int likeCount;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Widget placeholder() => Center(
      child: Icon(
        Icons.handyman_outlined,
        size: 28,
        color: colors.onSurfaceVariant,
      ),
    );
    final tile = Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.surfaceContainerHighest),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: imageUrl == null
                        ? placeholder()
                        : Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => placeholder(),
                            // Retain the full-card photo crop beneath the caption.
                            frameBuilder: (_, child, frame, _) => frame == null
                                ? placeholder()
                                : OverflowBox(
                                    alignment: Alignment.topCenter,
                                    minWidth: constraints.maxWidth,
                                    maxWidth: constraints.maxWidth,
                                    minHeight: constraints.maxHeight,
                                    maxHeight: constraints.maxHeight,
                                    child: child,
                                  ),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    color: colors.surface.withValues(alpha: .94),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle?.isNotEmpty == true)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        if (stageTitle != null || rating != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stageTitle ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (rating != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: colors.onSurface,
                                ),
                                Semantics(
                                  label: '${context.l10n.rating}: $rating',
                                  excludeSemantics: true,
                                  child: Text(
                                    '$rating',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (likeCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  left: 6,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      color: colors.inverseSurface.withValues(alpha: .82),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 12,
                            color: colors.onInverseSurface,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '$likeCount',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.onInverseSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return semanticLabel == null
        ? tile
        : Semantics(
            label: semanticLabel,
            button: onTap != null,
            onTap: onTap,
            excludeSemantics: true,
            child: tile,
          );
  }
}
