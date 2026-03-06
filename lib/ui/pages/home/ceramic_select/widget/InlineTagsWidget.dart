import 'package:ceramic_app/ui/widgets/adaptive/adaptive_text_field.dart';
import 'package:flutter/material.dart';

class InlineTagsWidget extends StatefulWidget {
  final List<String> initialTags;

  /// Called when a tag text changes
  final Future<void> Function(int index, String value)? onUpdate;

  /// Called when a tag is added
  final Future<void> Function(String value)? onAdd;

  /// Called when a tag is removed
  final Future<void> Function(int index)? onRemove;

  const InlineTagsWidget({
    super.key,
    this.onUpdate,
    this.onAdd,
    this.onRemove,
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

  Future<void> _addTag() async {
    final text = tagController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      tags.add(text);
      tagController.clear();
    });

    try {
      if (widget.onAdd != null) {
        await widget.onAdd!(text);
      }
    } catch (_) {
      setState(() {
        tags.removeLast();
      });
    }
  }

  Future<void> _removeTag(int index) async {
    final removedTag = tags[index];

    setState(() {
      tags.removeAt(index);
    });

    try {
      if (widget.onRemove != null) {
        await widget.onRemove!(index);
      }
    } catch (_) {
      setState(() {
        tags.insert(index, removedTag);
      });
    }
  }

  Future<void> _updateTag(int index, String value) async {
    final oldValue = tags[index];

    setState(() {
      tags[index] = value;
    });

    try {
      if (widget.onUpdate != null) {
        await widget.onUpdate!(index, value);
      }
    } catch (_) {
      setState(() {
        tags[index] = oldValue;
      });
    }
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
              onDeleted: () => _removeTag(index),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AdaptiveTextField(
                controller: tagController,
                labelText: "Add tag",
                maxLines: 1,
                onSubmitted: (_) async => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addTag,
              icon: const Icon(Icons.add_circle),
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    tagController.dispose();
    super.dispose();
  }
}