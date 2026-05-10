import 'package:flutter/material.dart';

import 'text_field_widget.dart';

class TagEntry {
  final int id;
  final String value;

  const TagEntry({
    required this.id,
    required this.value,
  });

  TagEntry copyWith({
    int? id,
    String? value,
  }) {
    return TagEntry(
      id: id ?? this.id,
      value: value ?? this.value,
    );
  }
}

class TagInputWidget extends StatefulWidget {
  final List<TagEntry> initialValues;

  /// return new tag id
  /// < 0 = failure
  final Future<int> Function(String value)? onCreate;

  /// return true = success
  /// return false = revert
  final Future<bool> Function(
      int id)? onRemove;

  final String placeholder;

  final double spacing;
  final double runSpacing;

  // TAG SIZE / STYLE
  final double horizontalPadding;
  final double verticalPadding;

  final double borderRadius;
  final double borderWidth;

  final Color borderColor;
  final Color backgroundColor;

  // TEXT STYLE
  final double fontSize;
  final FontWeight fontWeight;
  final String? fontFamily;
  final Color textColor;
  final TextDecoration decoration;

  // REMOVE ICON
  final double removeIconSize;
  final Color removeIconColor;
  final double removeIconSpacing;

  const TagInputWidget({
    super.key,
    this.initialValues = const [],
    this.onCreate,
    this.onRemove,
    this.placeholder = "Tag",

    this.spacing = 8,
    this.runSpacing = 8,

    this.horizontalPadding = 14,
    this.verticalPadding = 10,

    this.borderRadius = 10,
    this.borderWidth = 1,

    this.borderColor = Colors.black87,
    this.backgroundColor =
        Colors.transparent,

    this.fontSize = 16,
    this.fontWeight = FontWeight.w500,
    this.fontFamily,
    this.textColor = Colors.black,
    this.decoration =
        TextDecoration.none,

    this.removeIconSize = 18,
    this.removeIconColor =
        Colors.black,
    this.removeIconSpacing = 10,
  });

  @override
  State<TagInputWidget> createState() =>
      _TagInputWidgetState();
}

class _TagInputWidgetState
    extends State<TagInputWidget> {
  late List<TagEntry> tags;

  late List<TagEntry> lastValidTags;

  final GlobalKey<TextFieldWidgetState>
  _textFieldKey =
  GlobalKey<TextFieldWidgetState>();

  @override
  void initState() {
    super.initState();

    tags = [...widget.initialValues];
    lastValidTags = [
      ...widget.initialValues,
    ];
  }

  Future<void> _addTag(
      String value) async {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return;
    }

    final alreadyExists = tags.any(
          (tag) =>
      tag.value.toLowerCase() ==
          trimmed.toLowerCase(),
    );

    if (alreadyExists) {
      _textFieldKey.currentState
          ?.clear();

      return;
    }

    final optimisticTag = TagEntry(
      id: -999999,
      value: trimmed,
    );

    final previousTags = [
      ...lastValidTags,
    ];

    setState(() {
      tags = [
        ...tags,
        optimisticTag,
      ];
    });

    if (widget.onCreate == null) {
      final updatedTag =
      optimisticTag.copyWith(
        id: DateTime.now()
            .millisecondsSinceEpoch,
      );

      setState(() {
        tags.removeLast();
        tags.add(updatedTag);
      });

      lastValidTags = [...tags];

      _textFieldKey.currentState
          ?.clear();

      return;
    }

    final createdId =
    await widget.onCreate!(
      trimmed,
    );

    if (!mounted) {
      return;
    }

    if (createdId < 0) {
      setState(() {
        tags = previousTags;
      });

      return;
    }

    setState(() {
      tags.removeLast();

      tags.add(
        optimisticTag.copyWith(
          id: createdId,
        ),
      );
    });

    lastValidTags = [...tags];

    _textFieldKey.currentState
        ?.clear();
  }

  Future<void> _removeTag(
      TagEntry tag) async {
    final previousTags = [
      ...lastValidTags,
    ];

    setState(() {
      tags.removeWhere(
            (e) => e.id == tag.id,
      );
    });

    if (widget.onRemove == null) {
      lastValidTags = [...tags];
      return;
    }

    final success =
    await widget.onRemove!(
      tag.id,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        tags = previousTags;
      });

      return;
    }

    lastValidTags = [...tags];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Wrap(
          spacing: widget.spacing,
          runSpacing:
          widget.runSpacing,

          children: tags.map((tag) {
            return Container(
              padding:
              EdgeInsets.symmetric(
                horizontal: widget
                    .horizontalPadding,

                vertical: widget
                    .verticalPadding,
              ),

              decoration: BoxDecoration(
                color: widget
                    .backgroundColor,

                borderRadius:
                BorderRadius.circular(
                  widget.borderRadius,
                ),

                border: Border.all(
                  color:
                  widget.borderColor,

                  width:
                  widget.borderWidth,
                ),
              ),

              child: Row(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  Text(
                    tag.value,

                    style: TextStyle(
                      fontSize:
                      widget.fontSize,

                      fontWeight: widget
                          .fontWeight,

                      fontFamily: widget
                          .fontFamily,

                      color:
                      widget.textColor,

                      decoration: widget
                          .decoration,
                    ),
                  ),

                  SizedBox(
                    width: widget
                        .removeIconSpacing,
                  ),

                  GestureDetector(
                    onTap: () =>
                        _removeTag(tag),

                    child: Icon(
                      Icons.close,

                      size: widget
                          .removeIconSize,

                      color: widget
                          .removeIconColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        TextFieldWidget(
          key: _textFieldKey,

          placeholder:
          widget.placeholder,

          textInputAction:
          TextInputAction.done,

          onSubmitted:
              (value) async {
            await _addTag(value);

            return true;
          },
        ),
      ],
    );
  }
}