import 'package:flutter/material.dart';

import 'text_field_widget.dart';

class GlazeEntry {
  final int id;
  final int glazeId;
  final String glazeName;
  final String notes;
  final bool expanded;

  const GlazeEntry({
    required this.id,
    required this.glazeId,
    required this.glazeName,
    required this.notes,
    required this.expanded,
  });

  GlazeEntry copyWith({
    int? id,
    int? glazeId,
    String? glazeName,
    String? notes,
    bool? expanded,
  }) {
    return GlazeEntry(
      id: id ?? this.id,
      glazeId: glazeId ?? this.glazeId,
      glazeName: glazeName ?? this.glazeName,
      notes: notes ?? this.notes,
      expanded: expanded ?? this.expanded,
    );
  }
}

class GlazeInputWidget extends StatefulWidget {
  /// key = display name
  /// value = glaze id
  final List<MapEntry<String, int>> glazeEntries;

  final List<GlazeEntry> initialValues;

  /// return glaze entry id
  /// < 0 = failure
  final Future<int> Function(int glazeId)? onCreate;

  final Future<bool> Function(
      int glazeEntryId,
      )? onDelete;

  final Future<bool> Function(
      int glazeEntryId,
      String notes,
      )? onNotesChanged;

  // =========================
  // Styling
  // =========================

  final double titleFontSize;
  final FontWeight titleFontWeight;
  final String? titleFontFamily;
  final Color titleColor;
  final TextDecoration titleDecoration;

  final Duration? debounceDuration;

  final double dropdownFontSize;
  final FontWeight dropdownFontWeight;
  final String? dropdownFontFamily;
  final Color dropdownColor;
  final TextDecoration dropdownDecoration;

  final double iconSize;

  final Color backgroundColor;
  final Color dropdownBackgroundColor;

  final BorderRadius borderRadius;

  final EdgeInsetsGeometry itemPadding;
  final EdgeInsetsGeometry dropdownPadding;

  const GlazeInputWidget({
    super.key,
    required this.glazeEntries,
    this.initialValues = const [],
    this.onCreate,
    this.onDelete,
    this.onNotesChanged,

    this.debounceDuration,

    this.titleFontSize = 16,
    this.titleFontWeight = FontWeight.w600,
    this.titleFontFamily,
    this.titleColor = Colors.black,
    this.titleDecoration = TextDecoration.none,

    this.dropdownFontSize = 16,
    this.dropdownFontWeight = FontWeight.w500,
    this.dropdownFontFamily,
    this.dropdownColor = Colors.black,
    this.dropdownDecoration = TextDecoration.none,

    this.iconSize = 22,

    this.backgroundColor = const Color(
      0xFFF5F5F5,
    ),

    this.dropdownBackgroundColor =
    const Color(0xFFF1F1F1),

    this.borderRadius =
    const BorderRadius.all(
      Radius.circular(14),
    ),

    this.itemPadding =
    const EdgeInsets.all(14),

    this.dropdownPadding =
    const EdgeInsets.symmetric(
      horizontal: 16,
    ),
  });

  @override
  State<GlazeInputWidget> createState() =>
      _GlazeInputWidgetState();
}

class _GlazeInputWidgetState
    extends State<GlazeInputWidget> {
  late List<GlazeEntry> entries;

  late List<GlazeEntry> lastValidEntries;

  @override
  void initState() {
    super.initState();

    entries = [...widget.initialValues];
    lastValidEntries = [...widget.initialValues];
  }

  List<MapEntry<String, int>>
  get availableEntries {
    final selectedIds = entries
        .map((e) => e.glazeId)
        .toSet();

    return widget.glazeEntries
        .where(
          (entry) =>
      !selectedIds.contains(entry.value),
    )
        .toList();
  }

  Future<void> _createGlaze(
      int glazeId,
      ) async {
    final glaze = widget.glazeEntries.firstWhere(
          (entry) => entry.value == glazeId,
    );

    final optimisticEntry = GlazeEntry(
      id: -999999,
      glazeId: glaze.value,
      glazeName: glaze.key,
      notes: "",
      expanded: true,
    );

    final previous = [...lastValidEntries];

    setState(() {
      entries = [
        ...entries,
        optimisticEntry,
      ];
    });

    if (widget.onCreate == null) {
      final updated = optimisticEntry.copyWith(
        id: DateTime.now()
            .millisecondsSinceEpoch,
      );

      setState(() {
        entries.removeLast();
        entries.add(updated);
      });

      lastValidEntries = [...entries];

      return;
    }

    final createdId =
    await widget.onCreate!(glazeId);

    if (!mounted) {
      return;
    }

    if (createdId < 0) {
      setState(() {
        entries = previous;
      });

      return;
    }

    setState(() {
      entries.removeLast();

      entries.add(
        optimisticEntry.copyWith(
          id: createdId,
        ),
      );
    });

    lastValidEntries = [...entries];
  }

  Future<void> _deleteEntry(
      GlazeEntry entry,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Remove glaze?",
          ),

          content: Text(
            "Remove ${entry.glazeName}?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child: const Text(
                "Cancel",
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(
                "Remove",
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final previous = [...lastValidEntries];

    setState(() {
      entries.removeWhere(
            (e) => e.id == entry.id,
      );
    });

    if (widget.onDelete == null) {
      lastValidEntries = [...entries];
      return;
    }

    final success =
    await widget.onDelete!(entry.id);

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        entries = previous;
      });

      return;
    }

    lastValidEntries = [...entries];
  }

  Future<bool> _updateNotes(
      GlazeEntry entry,
      String notes,
      ) async {
    final previous = [...lastValidEntries];

    setState(() {
      entries = entries.map((e) {
        if (e.id != entry.id) {
          return e;
        }

        return e.copyWith(
          notes: notes,
        );
      }).toList();
    });

    if (widget.onNotesChanged == null) {
      lastValidEntries = [...entries];
      return true;
    }

    final success =
    await widget.onNotesChanged!(
      entry.id,
      notes,
    );

    if (!mounted) {
      return false;
    }

    if (!success) {
      return false;
    }

    lastValidEntries = [...entries];

    return true;
  }

  void _toggleExpanded(
      GlazeEntry entry,
      ) {
    setState(() {
      entries = entries.map((e) {
        if (e.id != entry.id) {
          return e;
        }

        return e.copyWith(
          expanded: !e.expanded,
        );
      }).toList();
    });

    lastValidEntries = [...entries];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 180,
          ),

          child: entries.isEmpty
              ? const SizedBox.shrink()
              : Column(
            children: entries.map((entry) {
              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 12,
                ),

                child: AnimatedContainer(
                  duration:
                  const Duration(
                    milliseconds: 180,
                  ),

                  padding:
                  widget.itemPadding,

                  decoration:
                  BoxDecoration(
                    color:
                    widget.backgroundColor,

                    borderRadius:
                    widget.borderRadius,
                  ),

                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .center,

                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,

                              onTap: () {
                                _toggleExpanded(
                                  entry,
                                );
                              },

                              child: SizedBox(
                                height: 36,

                                child: Row(
                                children: [
                                  AnimatedRotation(
                                    turns: entry
                                        .expanded
                                        ? 0.5
                                        : 0,

                                    duration:
                                    const Duration(
                                      milliseconds:
                                      180,
                                    ),

                                    child:
                                    Icon(
                                      Icons
                                          .keyboard_arrow_down,

                                      size:
                                      widget
                                          .iconSize,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Expanded(
                                    child: Text(
                                      entry
                                          .glazeName,

                                      style:
                                      TextStyle(
                                        fontSize:
                                        widget
                                            .titleFontSize,

                                        fontWeight:
                                        widget
                                            .titleFontWeight,

                                        fontFamily:
                                        widget
                                            .titleFontFamily,

                                        color:
                                        widget
                                            .titleColor,

                                        decoration:
                                        widget
                                            .titleDecoration,
                                      ),
                                    ),
                                  ),
                                ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 36,
                            height: 36,

                            child: IconButton(
                              padding:
                              EdgeInsets
                                  .zero,

                              constraints:
                              const BoxConstraints(),

                              onPressed: () {
                                _deleteEntry(
                                  entry,
                                );
                              },

                              icon:
                              Icon(
                                Icons.close,
                                size: widget
                                    .iconSize,
                              ),
                            ),
                          ),
                        ],
                      ),

                      AnimatedCrossFade(
                        firstChild:
                        const SizedBox
                            .shrink(),

                        secondChild:
                        Padding(
                          padding:
                          const EdgeInsets
                              .only(
                            top: 14,
                          ),

                          child:
                          TextFieldWidget(
                            initialValue:
                            entry.notes,

                            placeholder:
                            "Notes",

                            minLines: 3,
                            maxLines: 5,

                            debounceDuration: widget.debounceDuration,

                            onSubmitted: (value) async {
                              return await _updateNotes(
                                entry,
                                value,
                              );
                            },

                            onChanged: (value) async {
                              return await _updateNotes(
                                entry,
                                value,
                              );
                            },
                          ),
                        ),

                        crossFadeState:
                        entry.expanded
                            ? CrossFadeState
                            .showSecond
                            : CrossFadeState
                            .showFirst,

                        duration:
                        const Duration(
                          milliseconds:
                          180,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Container(
          padding:
          widget.dropdownPadding,

          decoration: BoxDecoration(
            color:
            widget.dropdownBackgroundColor,

            borderRadius:
            widget.borderRadius,
          ),

          child:
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: null,

              isExpanded: true,

              hint: Text(
                "Select",

                style: TextStyle(
                  color: const Color(
                    0xFF9A9A9A,
                  ),

                  fontSize:
                  widget
                      .dropdownFontSize,

                  fontWeight:
                  widget
                      .dropdownFontWeight,

                  fontFamily:
                  widget
                      .dropdownFontFamily,

                  decoration:
                  widget
                      .dropdownDecoration,
                ),
              ),

              icon: Icon(
                Icons
                    .arrow_drop_down,
                size:
                widget.iconSize,
                color: Color(0xFF9A9A9A),
              ),

              borderRadius:
              BorderRadius.circular(
                14,
              ),

              onChanged: (
                  value,
                  ) async {
                if (value == null) {
                  return;
                }

                await _createGlaze(
                  value,
                );
              },

              items: availableEntries.map((
                  entry,
                  ) {
                return DropdownMenuItem<
                    int>(
                  value: entry.value,

                  child: Text(
                    entry.key,

                    style: TextStyle(
                      fontSize:
                      widget
                          .dropdownFontSize,

                      fontWeight:
                      widget
                          .dropdownFontWeight,

                      fontFamily:
                      widget
                          .dropdownFontFamily,

                      color:
                      widget
                          .dropdownColor,

                      decoration:
                      widget
                          .dropdownDecoration,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}