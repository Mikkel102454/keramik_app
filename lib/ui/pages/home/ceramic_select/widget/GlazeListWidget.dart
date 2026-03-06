import 'dart:async';
import 'package:ceramic_app/ui/widgets/adaptive/adaptive_text_field.dart';
import 'package:flutter/material.dart';

class GlazeListWidget extends StatefulWidget {
  final List<String> glazes;

  /// Called when a glaze text changes (debounced)
  final Future<void> Function(int index, String value)? onUpdate;

  /// Called when a glaze is added
  final Future<void> Function()? onAdd;

  /// Called when a glaze is removed
  final Future<void> Function(int index)? onRemove;

  final Duration debounce;

  const GlazeListWidget({
    super.key,
    required this.glazes,
    this.onUpdate,
    this.onAdd,
    this.onRemove,
    this.debounce = const Duration(milliseconds: 500),
  });

  @override
  State<GlazeListWidget> createState() => _GlazeListWidgetState();
}

class _GlazeListWidgetState extends State<GlazeListWidget> {
  final Map<int, Timer> _timers = {};

  late List<String> _glazes;

  @override
  void initState() {
    super.initState();
    _glazes = List.from(widget.glazes);
  }

  Future<void> _handleUpdate(int index, String value) async {
    final oldValue = _glazes[index];

    setState(() {
      _glazes[index] = value;
    });

    try {
      await widget.onUpdate?.call(index, value);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _glazes[index] = oldValue;
      });
      rethrow;
    }
  }

  Future<void> _handleAdd() async {
    setState(() {
      _glazes.add("");
    });

    try {
      await widget.onAdd?.call();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _glazes.removeLast();
      });
    }
  }

  Future<void> _handleRemove(int index) async {
    final removedValue = _glazes[index];

    _timers[index]?.cancel();

    setState(() {
      _glazes.removeAt(index);
    });

    try {
      await widget.onRemove?.call(index);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _glazes.insert(index, removedValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_glazes.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: AdaptiveTextField(
                    initialValue: _glazes[index],
                    labelText: "",
                    maxLines: 1,
                    debounceDuration: Duration(milliseconds: 500),
                    onChanged: (value) async {
                      await _handleUpdate(index, value);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _handleRemove(index),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _handleAdd,
            icon: const Icon(Icons.add),
            label: const Text("Add glaze"),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}