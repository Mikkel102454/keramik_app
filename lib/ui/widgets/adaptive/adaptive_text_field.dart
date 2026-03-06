import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ceramic_app/utils/validation/validation_builder.dart';

class AdaptiveTextField extends StatefulWidget {
  final bool autocorrect;
  final AutovalidateMode autovalidateMode;
  final List<TextInputFormatter>? inputFormatters;
  final String? labelText;
  final TextInputType? keyboardType;
  final bool obscureText;

  final Future<void> Function(String)? onChanged;
  final Future<void> Function(String)? onSubmitted;

  final Duration? debounceDuration;

  final TextInputAction? textInputAction;
  final ValidationRuleCallback? validator;

  final int? minLines;
  final int? maxLines;

  final String? suffix;
  final String? initialValue;

  /// Optional external controller
  final TextEditingController? controller;

  const AdaptiveTextField({
    this.autocorrect = true,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.inputFormatters,
    this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.debounceDuration,
    this.textInputAction,
    this.validator,
    this.minLines,
    this.maxLines,
    this.suffix,
    this.initialValue,
    this.controller,
    super.key,
  });

  @override
  State<AdaptiveTextField> createState() => _AdaptiveTextFieldState();
}

class _AdaptiveTextFieldState extends State<AdaptiveTextField> {
  late final TextEditingController _internalController =
  TextEditingController(text: widget.initialValue);

  TextEditingController get controller =>
      widget.controller ?? _internalController;

  late bool obscureText = widget.obscureText;

  bool hadFirstFocus = false;
  bool forcedValidation = false;

  String? _lastValidValue;

  Timer? _debounce;

  bool get isValid =>
      widget.validator?.call(controller.text, context) == null;

  bool get showError {
    if (forcedValidation && !isValid) return true;

    switch (widget.autovalidateMode) {
      case AutovalidateMode.always:
        return !isValid;
      case AutovalidateMode.onUserInteraction:
        return !isValid && hadFirstFocus;
      case AutovalidateMode.disabled:
        return false;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _lastValidValue = controller.text;
  }

  @override
  void dispose() {
    _debounce?.cancel();

    if (widget.controller == null) {
      _internalController.dispose();
    }

    super.dispose();
  }

  void _revertValue() {
    if (_lastValidValue == null) return;

    controller.text = _lastValidValue!;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  Future<void> _executeChange(String value) async {
    try {
      if (widget.onChanged != null) {
        await widget.onChanged!(value);
      }

      _lastValidValue = value;
    } catch (_) {
      _revertValue();
    }
  }

  void _handleChanged(String value) {
    if (widget.debounceDuration == null) {
      _executeChange(value);
      return;
    }

    _debounce?.cancel();

    _debounce = Timer(widget.debounceDuration!, () {
      _executeChange(value);
    });
  }

  Future<void> _handleSubmitted(String value) async {
    forcedValidation = true;

    _debounce?.cancel();

    try {
      if (widget.onSubmitted != null) {
        await widget.onSubmitted!(value);
      }

      _lastValidValue = value;
    } catch (_) {
      _revertValue();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      autocorrect: widget.autocorrect,
      inputFormatters: widget.inputFormatters,
      keyboardType: widget.keyboardType,
      obscureText: obscureText,
      textInputAction: widget.textInputAction,
      onChanged: _handleChanged,
      onFieldSubmitted: _handleSubmitted,
      autovalidateMode: widget.autovalidateMode,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.labelText,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
        errorText:
        showError ? widget.validator?.call(controller.text, context) : null,
        suffixText: widget.suffix,
        suffixStyle: TextStyle(
          color: Theme.of(context).hintColor,
        ),
        suffixIcon: widget.obscureText
            ? IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () =>
              setState(() => obscureText = !obscureText),
        )
            : null,
      ),
      validator: (text) {
        forcedValidation = true;
        return widget.validator?.call(text, context);
      },
      onTap: () {
        hadFirstFocus = true;
      },
    );
  }
}