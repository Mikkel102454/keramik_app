import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DropdownWidget extends StatefulWidget {
  final String? placeholder;
  final String? initialValue;

  final Future<void> Function(String)? onChanged;

  final List<MapEntry<String, String>> entries;

  const DropdownWidget({
    super.key,
    this.placeholder,
    this.initialValue,
    this.onChanged,
    required this.entries,
  });

  @override
  State<DropdownWidget> createState() => _DropdownWidgetState();
}

class _DropdownWidgetState extends State<DropdownWidget> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();

    selectedValue = widget.initialValue;
  }

  Future<void> _handleChanged(String? value) async {
    if (value == null) {
      return;
    }

    setState(() {
      selectedValue = value;
    });

    if (widget.onChanged != null) {
      await widget.onChanged!(value);
    }
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
              color: Color(0xFF9A9A9A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          icon: const Icon(
            Icons.keyboard_arrow_down,
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