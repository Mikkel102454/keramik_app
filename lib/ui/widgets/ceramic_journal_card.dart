import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:flutter/material.dart';

class CeramicJournalCard extends StatelessWidget {
  const CeramicJournalCard({
    super.key,
    required this.ceramic,
    required this.stageTitle,
    required this.clayTitle,
    required this.onTap,
  });

  final CeramicDto ceramic;
  final String stageTitle;
  final String? clayTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = ceramic.images.isEmpty ? null : ceramic.images.first.uri;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Ink(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  image: image == null
                      ? null
                      : DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                ),
                child: image == null
                    ? Icon(
                        Icons.handyman_outlined,
                        size: 38,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ceramic.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          clayTitle?.isNotEmpty == true ? clayTitle! : stageTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 15, color: Color(0xffd89b25)),
                      Text('${ceramic.rating}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    stageTitle,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
