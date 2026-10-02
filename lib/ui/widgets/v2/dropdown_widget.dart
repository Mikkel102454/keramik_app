import 'package:flutter/material.dart';
import 'select_field_widget.dart';

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
  State<DropdownWidget> createState() => _DropdownWidgetState();
}

class _DropdownWidgetState extends State<DropdownWidget> {
  String? selectedValue;

  String? lastValidValue;

  @override
  void initState() {
    super.initState();

    final validValues = widget.entries.map((e) => e.value).toSet();

    if (widget.initialValue != null &&
        validValues.contains(widget.initialValue)) {
      selectedValue = widget.initialValue;
      lastValidValue = widget.initialValue;
    } else {
      selectedValue = null;
      lastValidValue = null;
    }
  }

  @override
  void didUpdateWidget(covariant DropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue ||
        widget.entries != oldWidget.entries) {
      final values = widget.entries.map((entry) => entry.value).toSet();
      final next = values.contains(widget.initialValue)
          ? widget.initialValue
          : null;
      selectedValue = next;
      lastValidValue = next;
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
    return SelectFieldWidget<String>(
      value: selectedValue,
      placeholder: widget.placeholder,
      onChanged: _handleChanged,
      items: widget.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.value,
              child: Text(entry.key),
            ),
          )
          .toList(),
    );
  }
}
