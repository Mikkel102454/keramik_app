import 'package:flutter/material.dart';

class TextInputWidget extends StatefulWidget {
  final String? label;
  final String? suffix;
  final String? hint;

  final ValueChanged<String>? onChanged;

  const TextInputWidget({
    super.key,
    this.label,
    this.suffix,
    this.hint,
    this.onChanged,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
              controller: controller,
              onChanged: widget.onChanged,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.text,

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