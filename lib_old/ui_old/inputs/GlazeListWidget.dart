import 'dart:async';
import 'package:flutter/material.dart';

class GlazeListWidget extends StatefulWidget {
  final List<String> glazes;

  /// Called when a glaze text changes (debounced)
  final Future<void> Function(int index, String value)? onUpdate;

  /// Called when a glaze is added
  final Future<void> Function(int index, TextEditingController controller)? onAdd;

  /// Called when a glaze is removed
  final Future<void> Function(int index, String value)? onRemove;

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
  final List<TextEditingController> _controllers = [];
  final Map<int, Timer> _timers = {};

  @override
  void initState() {
    super.initState();
    _buildControllers(widget.glazes);
  }

  @override
  void didUpdateWidget(covariant GlazeListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_listEquals(oldWidget.glazes, widget.glazes)) {
      _buildControllers(widget.glazes);
    }
  }

  void _buildControllers(List<String> glazes) {
    for (final c in _controllers) {
      c.dispose();
    }

    _controllers.clear();

    for (final glaze in glazes) {
      _controllers.add(TextEditingController(text: glaze));
    }

    setState(() {});
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _handleUpdate(int index, String value) async {
    _timers[index]?.cancel();

    _timers[index] = Timer(widget.debounce, () async {
      final oldValue = widget.glazes[index];

      try {
        await widget.onUpdate?.call(index, value);
      } catch (e) {
        // rollback text
        _controllers[index].text = oldValue;
      }
    });
  }

  Future<void> _handleAdd() async {
    final newIndex = _controllers.length;

    setState(() {
      _controllers.add(TextEditingController());
    });

    try {
      await widget.onAdd?.call(newIndex, _controllers.last);
    } catch (e) {
      // rollback add
      setState(() {
        _controllers.removeAt(newIndex);
      });
    }
  }

  Future<void> _handleRemove(int index) async {
    final removedValue = _controllers[index].text;

    setState(() {
      _controllers.removeAt(index);
    });

    try {
      await widget.onRemove?.call(index, removedValue);
    } catch (e) {
      // rollback remove
      setState(() {
        _controllers.insert(
          index,
          TextEditingController(text: removedValue),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) =>
                          _handleUpdate(index, value),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(14),
                        hintText: "Glaze note",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
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
        )
      ],
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}