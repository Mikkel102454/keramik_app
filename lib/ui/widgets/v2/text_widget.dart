import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final Color? color;
  final TextDecoration? decoration;


  const TextWidget({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.decoration,
    this.fontFamily,
    this.color
});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        decoration: decoration,
        color: color,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}