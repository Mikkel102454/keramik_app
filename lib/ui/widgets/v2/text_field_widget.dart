import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ceramic_app/utils/validation/validation_builder.dart';

class TextFieldWidget extends StatefulWidget {
  final bool autocorrect;
  final AutovalidateMode autovalidateMode;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final bool obscureText;

  /// return true = accept
  /// return false = revert
  final Future<bool> Function(String)? onChanged;

  /// return true = accept
  /// return false = revert
  final Future<bool> Function(String)? onSubmitted;

  final Duration? debounceDuration;

  final TextInputAction? textInputAction;
  final ValidationRuleCallback? validator;

  final int? minLines;
  final int? maxLines;

  final String? suffix;
  final String? placeholder;
  final String? initialValue;

  const TextFieldWidget({
    super.key,
    this.autocorrect = false,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.inputFormatters,
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
    this.placeholder,
    this.initialValue,
  });

  @override
  State<TextFieldWidget> createState() => TextFieldWidgetState();
}

class TextFieldWidgetState extends State<TextFieldWidget> {
  late final TextEditingController _controller;

  Timer? _debounce;

  bool hadFirstFocus = false;
  bool forcedValidation = false;

  late String lastValidValue;

  bool get isValid =>
      widget.validator?.call(_controller.text, context) == null;

  bool get showError {
    if (forcedValidation && !isValid) {
      return true;
    }

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

  void clear() {
    _controller.clear();

    lastValidValue = "";
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );

    lastValidValue = widget.initialValue ?? "";
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();

    super.dispose();
  }

  void _revertValue() {
    _controller.text = lastValidValue;

    _controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: _controller.text.length,
      ),
    );
  }

  Future<void> _executeChange(String value) async {
    if (widget.onChanged == null) {
      lastValidValue = value;
      return;
    }

    final success = await widget.onChanged!(value);

    if (!mounted) {
      return;
    }

    if (!success) {
      _revertValue();
      return;
    }

    lastValidValue = value;
  }

  void _onChanged(String value) {
    if (widget.debounceDuration != null) {
      _debounce?.cancel();

      _debounce = Timer(
        widget.debounceDuration!,
            () async {
          await _executeChange(value);
        },
      );

      return;
    }

    _executeChange(value);
  }

  Future<void> _handleSubmitted(String value) async {
    forcedValidation = true;

    if (widget.onSubmitted == null) {
      lastValidValue = value;

      setState(() {});

      return;
    }

    final success = await widget.onSubmitted!(value);

    if (!mounted) {
      return;
    }

    if (!success) {
      _revertValue();

      setState(() {});

      return;
    }

    lastValidValue = value;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      autocorrect: widget.autocorrect,
      autovalidateMode: widget.autovalidateMode,
      inputFormatters: widget.inputFormatters,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      textInputAction: widget.textInputAction,
      minLines: widget.minLines ?? 1,
      maxLines: widget.maxLines ?? 1,

      onChanged: _onChanged,

      onFieldSubmitted: _handleSubmitted,

      onTap: () {
        hadFirstFocus = true;
      },

      validator: (text) {
        forcedValidation = true;

        return widget.validator?.call(text, context);
      },

      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: widget.placeholder,

        hintStyle: const TextStyle(
          color: Color(0xFF9A9A9A),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),

        errorText: showError
            ? widget.validator?.call(_controller.text, context)
            : null,

        suffixText: widget.suffix,

        suffixStyle: const TextStyle(
          color: Color(0xFF8E8E93),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),

        filled: true,
        fillColor: const Color(0xFFF1F1F1),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD8D8D8),
            width: 1,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
      ),
    );
  }
}