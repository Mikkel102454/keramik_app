import 'package:flutter/material.dart';

class SmartRow extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onPressed;

  const SmartRow({
    super.key,
    required this.children,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (onPressed != null) {
          await onPressed!();
        }
      },
      child: Row(
        children: children,
      ),
    );
  }
}