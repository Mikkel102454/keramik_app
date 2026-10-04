import 'dart:io';

import 'package:ceramic_app/objects/image_dto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class ImageViewPage extends StatelessWidget {
  final ImageDto? image;
  final XFile? xFile;

  final Future<void> Function() onDelete;

  const ImageViewPage({
    super.key,
    this.image,
    this.xFile,
    required this.onDelete,
  }) : assert(
         image != null || xFile != null,
         'Either image or xFile must be provided',
       );

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (xFile != null) {
      imageWidget = Image.file(
        File(xFile!.path),
        fit: BoxFit.contain,
        errorBuilder: (context, _, _) => _imageError(context),
      );
    } else {
      imageWidget = Image.network(
        image!.uri,
        fit: BoxFit.contain,
        errorBuilder: (context, _, _) => _imageError(context),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.all(12),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageWidget,
                ),
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.delete,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(context.l10n.deleteImageQuestion),
                          content: Text(context.l10n.cannotUndo),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: Text(context.l10n.cancel),
                            ),

                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: Text(context.l10n.delete),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) {
                        return;
                      }

                      await onDelete();
                    },
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                      size: 32,
                    ),
                  ),

                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageError(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.photoLoadFailed, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
