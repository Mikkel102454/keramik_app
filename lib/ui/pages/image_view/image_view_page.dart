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
      );

    } else {

      imageWidget = Image.network(
        image!.uri,
        fit: BoxFit.contain,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
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
                  onPressed: () async {

                    final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                          context.l10n.deleteImageQuestion,
                        ),
                        content: Text(
                          context.l10n.cannotUndo,
                        ),
                        actions: [

                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },
                            child: Text(
                              context.l10n.cancel,
                            ),
                          ),

                          FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                            child: Text(
                              context.l10n.delete,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) {
                      return;
                    }

                    await onDelete();
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
