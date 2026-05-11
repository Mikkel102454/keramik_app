import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SquareWidget extends StatelessWidget {

  final String? title;
  final FontWeight? fontWeight;
  final double? fontSize;

  final String? imageUri;
  final XFile? imageFile;

  final String? fontFamily;
  final Color fontColor;
  final TextDecoration? fontDecoration;
  final Color backgroundColor;

  final IconData? icon;
  final double? iconSize;
  final Color iconColor;

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
    this.fontColor = Colors.white,
    this.fontDecoration,
    this.backgroundColor = Colors.blue,

    this.icon,
    this.iconSize,
    this.iconColor = Colors.white,

    this.borderRadius = 8,
    this.opacity = 1,

    this.onPressed,

    this.width,
    this.height,

    this.direction = Axis.vertical,
    this.mainAxisAlignment =
        MainAxisAlignment.center,
    this.crossAxisAlignment =
        CrossAxisAlignment.center,

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
          color: iconColor,
          size: iconSize,
        ),

      if (title != null)
        Text(
          title!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fontColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            decoration: fontDecoration,
          ),
        ),
    ];

    final orderedChildren =
    reverse
        ? children.reversed.toList()
        : children;

    final spacedChildren = <Widget>[];

    for (int i = 0;
    i < orderedChildren.length;
    i++) {

      spacedChildren.add(
        orderedChildren[i],
      );

      if (i != orderedChildren.length - 1) {

        spacedChildren.add(
          direction == Axis.vertical
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
    }

    DecorationImage? backgroundImage;

    if (imageUri != null) {

      backgroundImage = DecorationImage(
        image: NetworkImage(imageUri!),
        fit: BoxFit.cover,
      );

    } else if (imageFile != null) {

      backgroundImage = DecorationImage(
        image: FileImage(
          File(imageFile!.path),
        ),
        fit: BoxFit.cover,
      );
    }

    return Material(
      color: Colors.transparent,

      borderRadius:
      BorderRadius.circular(borderRadius),

      child: InkWell(
        onTap: onPressed,

        borderRadius:
        BorderRadius.circular(borderRadius),

        child: Opacity(
          opacity: opacity,

          child: Container(
            width: width ?? double.infinity,
            height: height ?? double.infinity,

            decoration: BoxDecoration(
              color: backgroundColor,

              borderRadius:
              BorderRadius.circular(
                borderRadius,
              ),

              image: backgroundImage,
            ),

            alignment: Alignment.center,

            child: Container(
              width: double.infinity,
              height: double.infinity,

              padding:
              const EdgeInsets.all(8),

              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                  borderRadius,
                ),

                color:
                backgroundImage != null
                    ? Colors.black
                    .withValues(alpha: 0)
                    : Colors.transparent,
              ),

              child: Flex(
                direction: direction,

                mainAxisAlignment:
                mainAxisAlignment,

                crossAxisAlignment:
                crossAxisAlignment,

                mainAxisSize:
                MainAxisSize.max,

                children: spacedChildren,
              ),
            ),
          ),
        ),
      ),
    );
  }
}