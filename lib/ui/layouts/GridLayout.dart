import 'package:flutter/material.dart';

class GridLayout extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;

  final Axis scrollDirection;

  final Future<void> Function()? onRefresh;

  const GridLayout({
    super.key,
    required this.children,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.padding = const EdgeInsets.all(16),

    this.scrollDirection = Axis.vertical,

    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      scrollDirection: scrollDirection,

      physics: const BouncingScrollPhysics(),
      padding: padding,

      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),

      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: grid,
      );
    }

    return grid;
  }
}