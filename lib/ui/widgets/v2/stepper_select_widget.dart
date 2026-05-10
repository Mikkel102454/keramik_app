import 'package:flutter/material.dart';

class StepperSelectWidget extends StatefulWidget {
  final List<MapEntry<String, String>> entries;
  final String initialValue;
  final Future<bool> Function(String value)? onChanged;

  final double size;
  final double spacing;

  final double fontSize;
  final FontWeight fontWeight;
  final String? fontFamily;
  final Color color;
  final TextDecoration decoration;

  const StepperSelectWidget({
    super.key,
    required this.entries,
    required this.initialValue,
    this.onChanged,
    this.size = 40,
    this.spacing = 16,

    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.fontFamily,
    this.color = Colors.black,
    this.decoration = TextDecoration.none,
  });

  @override
  State<StepperSelectWidget> createState() =>
      _StepperSelectWidgetState();
}

class _StepperSelectWidgetState
    extends State<StepperSelectWidget> {
  late String selectedValue;

  late String lastValidValue;

  @override
  void initState() {
    super.initState();

    selectedValue = widget.initialValue;
    lastValidValue = widget.initialValue;
  }

  int get selectedIndex {
    return widget.entries.indexWhere(
          (entry) => entry.value == selectedValue,
    );
  }

  Future<void> _handleTap(String value) async {
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: List.generate(
          widget.entries.length,
              (index) {
            final entry = widget.entries[index];

            final isSelected = index <= selectedIndex;

            return Padding(
              padding: EdgeInsets.only(
                right: index == widget.entries.length - 1
                    ? 0
                    : widget.spacing,
              ),

              child: GestureDetector(
                onTap: () => _handleTap(entry.value),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 180,
                      ),

                      width: widget.size,
                      height: widget.size,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: isSelected
                            ? const Color(0xFF34C759)
                            : const Color(0xFFD9D9D9),
                      ),

                      child: isSelected
                          ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: widget.size * 0.5,
                      )
                          : null,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: widget.fontWeight,
                        fontFamily: widget.fontFamily,
                        color: widget.color,
                        decoration: widget.decoration,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}