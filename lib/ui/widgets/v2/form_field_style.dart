import 'package:flutter/material.dart';

/// Shared by the app theme and the field widgets. Pages supply data, not borders.
abstract final class FormFieldStyle {
  static const radius = 14.0;
  static const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 12);

  static InputDecorationTheme theme(ColorScheme colors) {
    OutlineInputBorder border([Color? color]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: color == null ? BorderSide.none : BorderSide(color: color),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      contentPadding: padding,
      hintStyle: textStyle.copyWith(color: colors.onSurfaceVariant),
      suffixStyle: textStyle.copyWith(color: colors.onSurfaceVariant),
      errorMaxLines: 3,
      border: border(),
      enabledBorder: border(),
      disabledBorder: border(),
      focusedBorder: border(colors.outline),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error),
    );
  }

  static InputDecoration decoration(
    BuildContext context, {
    String? hint,
    String? suffix,
    Widget? suffixIcon,
    String? error,
  }) => InputDecoration(
    hintText: hint,
    suffixText: suffix,
    suffixIcon: suffixIcon,
    errorText: error,
  ).applyDefaults(theme(Theme.of(context).colorScheme));
}

/// Labels sit above controls so multiline labels never overlap entered values.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, this.label, required this.child});
  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null) ...[
        Text(
          label!,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
      ],
      child,
    ],
  );
}
