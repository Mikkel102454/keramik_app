import 'dart:io';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SquareWidget extends StatelessWidget {
  final String? title;
  final FontWeight? fontWeight;
  final double? fontSize;

  final String? imageUri;
  final XFile? imageFile;

  final String? fontFamily;
  final Color? fontColor;
  final TextDecoration? fontDecoration;
  final Color? backgroundColor;

  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;

  final Future<void> Function()? onPressed;

  final double borderRadius;
  final double opacity;

  final double? width;
  final double? height;

  // Layout controls
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool reverse;

  const SquareWidget({
    super.key,
    this.title,
    this.fontWeight,
    this.fontSize,

    this.imageUri,
    this.imageFile,

    this.fontFamily,
    this.fontColor,
    this.fontDecoration,
    this.backgroundColor,

    this.icon,
    this.iconSize,
    this.iconColor,

    this.borderRadius = 8,
    this.opacity = 1,

    this.onPressed,

    this.width,
    this.height,

    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,

    this.spacing = 6,
    this.reverse = false,
  }) : assert(
         imageUri == null || imageFile == null,
         'Cannot provide both imageUri and imageFile',
       );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (icon != null)
        Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
          size: iconSize,
        ),

      if (title != null)
        Text(
          title!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                fontColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            decoration: fontDecoration,
          ),
        ),
    ];

    final orderedChildren = reverse ? children.reversed.toList() : children;

    final spacedChildren = <Widget>[];

    for (int i = 0; i < orderedChildren.length; i++) {
      spacedChildren.add(orderedChildren[i]);

      if (i != orderedChildren.length - 1) {
        spacedChildren.add(
          direction == Axis.vertical
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
    }

    Widget? backgroundImage;
    Widget failedImage() => Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    if (imageUri != null) {
      backgroundImage = Image.network(
        imageUri!,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, _, _) => failedImage(),
      );
    } else if (imageFile != null) {
      backgroundImage = Image.file(
        File(imageFile!.path),
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => failedImage(),
      );
    }

    return Material(
      color: Colors.transparent,

      borderRadius: BorderRadius.circular(borderRadius),

      clipBehavior: Clip.antiAlias,
      child: Semantics(
        label: onPressed == null || title != null
            ? null
            : backgroundImage != null
            ? context.l10n.viewPhoto
            : context.l10n.uploadPhoto,
        child: InkWell(
          onTap: onPressed,

          borderRadius: BorderRadius.circular(borderRadius),

          child: Opacity(
            opacity: opacity,

            child: Container(
              width: width ?? double.infinity,
              height: height ?? double.infinity,

              decoration: BoxDecoration(
                color:
                    backgroundColor ??
                    Theme.of(context).colorScheme.primaryContainer,

                borderRadius: BorderRadius.circular(borderRadius),
              ),

              alignment: Alignment.center,

              child: Stack(
                fit: StackFit.expand,
                children: [
                  ?backgroundImage,
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Flex(
                      direction: direction,
                      mainAxisAlignment: mainAxisAlignment,
                      crossAxisAlignment: crossAxisAlignment,
                      mainAxisSize: MainAxisSize.max,
                      children: spacedChildren,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
