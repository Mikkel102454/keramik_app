import 'package:flutter/material.dart';

class SquareWidget extends StatelessWidget {
  final String? title;
  final FontWeight? fontWeight;
  final double? fontSize;
  final String? imageUri;
  final String? fontFamily;
  final Color fontColor;
  final TextDecoration? fontDecoration;
  final Color backgroundColor;
  final IconData? icon;
  final double? iconSize;
  final Color iconColor;
  final VoidCallback? onTap;
  final double borderRadius;
  final double opacity;

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
    this.fontFamily,
    this.fontColor = Colors.white,
    this.fontDecoration,
    this.backgroundColor = Colors.blue,
    this.icon,
    this.iconSize,
    this.iconColor = Colors.white,
    this.borderRadius = 8,
    this.opacity = 1,
    this.onTap,

    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 6,
    this.reverse = false,
  });

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
    reverse ? children.reversed.toList() : children;

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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              image: imageUri != null
                  ? DecorationImage(
                image: NetworkImage(imageUri!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(borderRadius),
                color: imageUri != null
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
              child: Flex(
                direction: direction,
                mainAxisAlignment: mainAxisAlignment,
                crossAxisAlignment: crossAxisAlignment,
                mainAxisSize: MainAxisSize.max,
                children: spacedChildren,
              ),
            ),
          ),
        ),
      ),
    );
  }
}