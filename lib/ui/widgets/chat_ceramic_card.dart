import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:flutter/material.dart';

class ChatCeramicCard extends StatelessWidget {
  const ChatCeramicCard({
    required this.card,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final ChatCeramicCardDto card;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (!card.available) {
      return Semantics(
        button: onLongPress != null,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Card(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hide_image_outlined),
                  const SizedBox(width: 10),
                  Flexible(child: Text(context.l10n.ceramicUnavailable)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: context.l10n.openSharedCeramic(card.title ?? ''),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      image: card.imageUrl == null
                          ? null
                          : DecorationImage(
                              image: NetworkImage(card.imageUrl!),
                              fit: BoxFit.contain,
                            ),
                    ),
                    child: card.imageUrl == null
                        ? const Icon(Icons.handyman_outlined, size: 42)
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              card.clayTitle?.isNotEmpty == true
                                  ? card.clayTitle!
                                  : localizedStageName(context.l10n, card.stage ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xffd89b25),
                          ),
                          Text('${card.rating ?? 0}'),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        localizedStageName(context.l10n, card.stage ?? ''),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
