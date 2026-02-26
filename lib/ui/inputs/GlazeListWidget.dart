import 'dart:async';

import 'package:flutter/material.dart';

class GlazeListWidget extends StatefulWidget {
  final Function(List<String>) onChanged;
  final Function(List<String>)? delayedCallback;
  final List<String> initialGlazes;
  final Duration callbackDelay;

  const GlazeListWidget({
    super.key,
    required this.onChanged,
    this.delayedCallback,
    this.callbackDelay = const Duration(milliseconds: 500),
    this.initialGlazes = const [],
  });

  @override
  State<GlazeListWidget> createState() => _GlazeListWidgetState();
}

class _GlazeListWidgetState extends State<GlazeListWidget> {
  final List<TextEditingController> _glazeControllers = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    for (var glaze in widget.initialGlazes) {
      _glazeControllers.add(TextEditingController(text: glaze));
    }
  }

  void _updateGlazes() {
    final glazeNotes = _glazeControllers.map((c) => c.text.trim()).toList();
    widget.onChanged(glazeNotes);
  }

  void _onChanged() {
    final glazeNotes = _glazeControllers.map((c) => c.text.trim()).toList();

    if (widget.delayedCallback != null) {
      _timer?.cancel();
      _timer = Timer(widget.callbackDelay, () {
        widget.delayedCallback!(glazeNotes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_glazeControllers.length, (index) {
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
                      controller: _glazeControllers[index],
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => _onChanged(),
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
                  onPressed: () {
                    setState(() {
                      _glazeControllers.removeAt(index);
                    });
                    _updateGlazes();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                )
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _glazeControllers.add(TextEditingController());
              });
              _updateGlazes();
            },
            icon: const Icon(Icons.add),
            label: const Text("Add glaze"),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _glazeControllers) {
      _timer?.cancel();
      controller.dispose();
    }
    super.dispose();
  }
}
