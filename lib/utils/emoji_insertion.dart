import 'package:flutter/services.dart';

/// Insert a complete Unicode sequence at the current selection without splitting it.
TextEditingValue insertChatEmoji(TextEditingValue value, String emoji) {
  final selection = value.selection;
  final start = selection.isValid ? selection.start : value.text.length;
  final end = selection.isValid ? selection.end : value.text.length;
  final text = value.text.replaceRange(start, end, emoji);
  if (text.runes.length > 2000) return value;
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: start + emoji.length),
  );
}
