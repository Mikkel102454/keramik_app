import 'package:flutter/material.dart';

class CollapseGridLayout extends StatelessWidget {
  final String title;
  final Widget? child;

  const CollapseGridLayout({
    super.key,
    required this.title,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = child != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,

          // prevents greyed-out disabled style
          disabledColor: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        child: ExpansionTile(
          enabled: hasChildren, // stops expansion
          showTrailingIcon: hasChildren,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          childrenPadding: const EdgeInsets.only(bottom: 8),

          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          children: hasChildren ? [child!] : const [],
        ),
      ),
    );
  }
}