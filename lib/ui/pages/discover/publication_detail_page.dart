import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/repositories/publication_repository.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class PublicationDetailPage extends StatefulWidget {
  const PublicationDetailPage({
    required this.publicationId,
    this.initialDetail,
    super.key,
  });

  final String publicationId;
  final PublicationDetailDto? initialDetail;

  @override
  State<PublicationDetailPage> createState() => _PublicationDetailPageState();
}

class _PublicationDetailPageState extends State<PublicationDetailPage> {
  int _imagePage = 0;
  late Future<PublicationDetailDto> _detail = widget.initialDetail == null
      ? PublicationRepository.detail(widget.publicationId)
      : Future.value(widget.initialDetail);

  void _retry() {
    setState(() {
      _imagePage = 0;
      _detail = PublicationRepository.detail(widget.publicationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navigationDiscover)),
      body: FutureBuilder<PublicationDetailDto>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: OutlinedButton(
                onPressed: _retry,
                child: Text(context.l10n.retry),
              ),
            );
          }
          final detail = snapshot.data!;
          final requestedImageHeight = MediaQuery.sizeOf(context).height * .42;
          final imageHeight =
              requestedImageHeight > 460 ? 460.0 : requestedImageHeight;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (detail.images.isNotEmpty)
                SizedBox(
                  height: imageHeight,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: detail.images.length,
                        onPageChanged: (value) {
                          setState(() => _imagePage = value);
                        },
                        itemBuilder: (context, index) => ColoredBox(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Image.network(
                              detail.images[index].uri,
                              width: double.infinity,
                              height: imageHeight,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              gaplessPlayback: true,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                final expected = progress.expectedTotalBytes;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: expected == null
                                        ? null
                                        : progress.cumulativeBytesLoaded /
                                            expected,
                                  ),
                                );
                              },
                              errorBuilder: (_, _, _) => const Center(
                                child:
                                    Icon(Icons.broken_image_outlined, size: 48),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (detail.images.length > 1)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .65),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              child: Text(
                                '${_imagePage + 1}/${detail.images.length}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProfileAvatar(
                          initials: detail.creator.avatarInitials,
                          colorHex: detail.creator.avatarColor,
                          imageUrl: detail.creator.avatarUrl,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(detail.creator.username)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      detail.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (detail.clay?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text('${context.l10n.clay}: ${detail.clay}'),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 18),
                        const SizedBox(width: 5),
                        Text('${detail.likeCount}'),
                        const SizedBox(width: 18),
                        const Icon(Icons.star_rounded, size: 18),
                        const SizedBox(width: 5),
                        Text('${detail.rating}'),
                      ],
                    ),
                    if (detail.tags.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.tags,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Wrap(
                        spacing: 7,
                        children: detail.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                    ],
                    if (detail.outcome?.isNotEmpty == true) ...[
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.outcome,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(detail.outcome!),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
