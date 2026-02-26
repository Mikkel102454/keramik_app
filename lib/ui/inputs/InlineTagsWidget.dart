import 'package:flutter/material.dart';

class InlineTagsWidget extends StatefulWidget {
  final Function(List<String>) onChanged;
  final List<String> initialTags;

  const InlineTagsWidget({
    super.key,
    required this.onChanged,
    this.initialTags = const [],
  });

  @override
  State<InlineTagsWidget> createState() => _InlineTagsWidgetState();
}

class _InlineTagsWidgetState extends State<InlineTagsWidget> {
  late List<String> tags;
  final tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tags = List.from(widget.initialTags);
  }

  void _addTag() {
    final text = tagController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      tags.add(text);
      tagController.clear();
    });

    widget.onChanged(tags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(tags.length, (index) {
            return Chip(
              backgroundColor: Colors.grey[800],
              label: Text(
                tags[index],
                style: const TextStyle(color: Colors.white),
              ),
              deleteIconColor: Colors.white54,
              onDeleted: () {
                setState(() {
                  tags.removeAt(index);
                });
                widget.onChanged(tags);
              },
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: tagController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    hintText: "Add tag...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addTag,
              icon: const Icon(Icons.add_circle),
              color: Colors.green,
            ),
          ],
        )
      ],
    );
  }

  @override
  void dispose() {
    tagController.dispose();
    super.dispose();
  }
}
