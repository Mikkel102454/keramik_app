import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberInputWidget extends StatefulWidget {
  final String? label;
  final String? suffix;
  final String? hint;

  final TextEditingController controller;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? delayedCallback;
  final Duration callbackDelay;

  const NumberInputWidget({
    super.key,
    this.label,
    this.suffix,
    this.hint,
    required this.controller,
    this.onChanged,
    this.delayedCallback,
    this.callbackDelay = const Duration(milliseconds: 500),
  });

  @override
  State<NumberInputWidget> createState() => _NumberInputWidgetState();
}

class _NumberInputWidgetState extends State<NumberInputWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);

    if (widget.delayedCallback != null) {
      _timer?.cancel();
      _timer = Timer(widget.callbackDelay, () {
        widget.delayedCallback!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Text(
              widget.label!,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: widget.controller,
              onChanged: _onChanged,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d*'),
                ),
              ],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(14),
                hintText: widget.hint ?? widget.label,
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                suffixText: widget.suffix,
                suffixStyle: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
