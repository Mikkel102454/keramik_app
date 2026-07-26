import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:flutter/material.dart';

class ChatPublicationCard extends StatelessWidget {
  const ChatPublicationCard({
    required this.card,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final ChatPublicationCardDto card;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final publication = card.publication;
    if (!card.available || publication == null) {
      return GestureDetector(
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
                Flexible(child: Text(context.l10n.publicationUnavailable)),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
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
                child: publication.primaryImage == null
                    ? const Center(child: Icon(Icons.handyman_outlined, size: 42))
                    : Image.network(
                        publication.primaryImage!.uri,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined, size: 42),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      publication.creator.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 15),
                        const SizedBox(width: 4),
                        Text('${publication.likeCount}'),
                        if (publication.clay?.isNotEmpty == true) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              publication.clay!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
