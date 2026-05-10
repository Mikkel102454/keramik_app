import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DropdownWidget extends StatefulWidget {
  final String? placeholder;
  final String? initialValue;

  /// return true = accept
  /// return false = revert
  final Future<bool> Function(String)? onChanged;

  final List<MapEntry<String, String>> entries;

  const DropdownWidget({
    super.key,
    this.placeholder,
    this.initialValue,
    this.onChanged,
    required this.entries,
  });

  @override
  State<DropdownWidget> createState() =>
      _DropdownWidgetState();
}

class _DropdownWidgetState
    extends State<DropdownWidget> {
  String? selectedValue;

  String? lastValidValue;

  @override
  void initState() {
    super.initState();

    final validValues = widget.entries
        .map((e) => e.value)
        .toSet();

    if (widget.initialValue != null &&
        validValues.contains(widget.initialValue)) {
      selectedValue = widget.initialValue;
      lastValidValue = widget.initialValue;
    } else {
      selectedValue = null;
      lastValidValue = null;
    }
  }

  Future<void> _handleChanged(String? value) async {
    if (value == null) {
      return;
    }

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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(14),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,

          isExpanded: true,

          hint: Text(
            widget.placeholder ?? "Please Select",

            style: const TextStyle(
              color: Color(0xFF707070),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF9A9A9A),
          ),

          borderRadius: BorderRadius.circular(14),

          onChanged: _handleChanged,

          items: widget.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,

              child: Text(entry.key),
            );
          }).toList(),
        ),
      ),
    );
  }
}