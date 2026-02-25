import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SquareWidgetIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final String? imageUri;
  final IconData icon;
  final double iconSize;
  final Color iconColor;

  const SquareWidgetIcon({
    super.key,
    this.imageUri,
    required this.icon,
    this.iconSize = 30,
    this.iconColor = Colors.white70,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),

          image: imageUri != null
              ? DecorationImage(
            image: NetworkImage(imageUri!),
            fit: BoxFit.cover,
          ) : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}