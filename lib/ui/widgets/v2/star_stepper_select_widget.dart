import 'package:flutter/material.dart';

class StarStepperSelectWidget extends StatefulWidget {
  final int count;

  final int initialValue;

  final Future<bool> Function(int value)? onChanged;

  final double size;
  final double spacing;

  final double fontSize;
  final FontWeight fontWeight;
  final String? fontFamily;
  final Color color;
  final TextDecoration decoration;

  final IconData selectedIcon;
  final IconData unselectedIcon;

  final Color selectedIconColor;
  final Color unselectedIconColor;

  final bool showLabel;

  const StarStepperSelectWidget({
    super.key,

    this.count = 5,
    required this.initialValue,
    this.onChanged,

    this.size = 28,
    this.spacing = 4,

    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.fontFamily,
    this.color = Colors.black,
    this.decoration = TextDecoration.none,

    this.selectedIcon = Icons.star,
    this.unselectedIcon = Icons.star_border,

    this.selectedIconColor = const Color(0xFF34C759),
    this.unselectedIconColor = const Color(0xFFD9D9D9),

    this.showLabel = false,
  });

  @override
  State<StarStepperSelectWidget> createState() =>
      _StarStepperSelectWidgetState();
}

class _StarStepperSelectWidgetState
    extends State<StarStepperSelectWidget> {
  late int selectedValue;

  late int lastValidValue;

  @override
  void initState() {
    super.initState();

    selectedValue = widget.initialValue;
    lastValidValue = widget.initialValue;
  }

  Future<void> _handleTap(int value) async {
    if (value == selectedValue) {
      return;
    }

    setState(() {
      selectedValue = value;
    });

    if (widget.onChanged == null) {
      lastValidValue = value;
      return;
    }

    final success = await widget.onChanged!(value);

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        selectedValue = lastValidValue;
      });

      return;
    }

    lastValidValue = value;

    setState(() {
      selectedValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: List.generate(
        widget.count,
            (index) {
          final starValue = index + 1;

          final isSelected = starValue <= selectedValue;

          return Padding(
            padding: EdgeInsets.only(
              right: index == widget.count - 1
                  ? 0
                  : widget.spacing,
            ),

            child: GestureDetector(
              onTap: () => _handleTap(starValue),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? widget.selectedIcon
                        : widget.unselectedIcon,

                    size: widget.size,

                    color: isSelected
                        ? widget.selectedIconColor
                        : widget.unselectedIconColor,
                  ),

                  if (widget.showLabel) ...[
                    const SizedBox(height: 6),

                    Text(
                      "$starValue",
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: widget.fontWeight,
                        fontFamily: widget.fontFamily,
                        color: widget.color,
                        decoration: widget.decoration,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}