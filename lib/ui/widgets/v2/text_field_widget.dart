import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clay_dock/utils/validation/validation_builder.dart';
import 'form_field_style.dart';

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
  final TextEditingController? controller;
  final String? label;
  final String? semanticsLabel;
  final int? maxLength;
  final Widget? suffixIcon;
  final String? errorText;
  final bool enabled;
  final bool readOnly;

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
    this.controller,
    this.label,
    this.semanticsLabel,
    this.maxLength,
    this.suffixIcon,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
  }) : assert(controller == null || initialValue == null);

  @override
  State<TextFieldWidget> createState() => TextFieldWidgetState();
}

class TextFieldWidgetState extends State<TextFieldWidget> {
  late TextEditingController _controller;
  bool get _ownsController => widget.controller == null;

  Timer? _debounce;

  bool hadFirstFocus = false;
  bool forcedValidation = false;

  late String lastValidValue;

  bool get isValid => widget.validator?.call(_controller.text, context) == null;

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

    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);

    lastValidValue = _controller.text;
  }

  @override
  void didUpdateWidget(covariant TextFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _debounce?.cancel();
      if (oldWidget.controller == null) _controller.dispose();
      _controller =
          widget.controller ?? TextEditingController(text: widget.initialValue);
      lastValidValue = _controller.text;
    } else if (_ownsController &&
        widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
      lastValidValue = _controller.text;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_ownsController) _controller.dispose();

    super.dispose();
  }

  void _revertValue() {
    _controller.text = lastValidValue;

    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
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

      _debounce = Timer(widget.debounceDuration!, () async {
        await _executeChange(value);
      });

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
    return FieldLabel(
      label: widget.label,
      child: Semantics(
        label: widget.semanticsLabel ?? widget.label,
        child: TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autocorrect: widget.autocorrect,
          autovalidateMode: widget.autovalidateMode,
          inputFormatters: widget.inputFormatters,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          minLines: widget.minLines ?? 1,
          maxLines: widget.maxLines ?? 1,
          maxLength: widget.maxLength,
          onChanged: _onChanged,
          onFieldSubmitted: _handleSubmitted,
          onTap: () => hadFirstFocus = true,
          validator: (text) {
            forcedValidation = true;
            return widget.validator?.call(text, context);
          },
          style: FormFieldStyle.textStyle,
          decoration: FormFieldStyle.decoration(
            context,
            hint: widget.placeholder,
            suffix: widget.suffix,
            suffixIcon: widget.suffixIcon,
            error:
                widget.errorText ??
                (showError
                    ? widget.validator?.call(_controller.text, context)
                    : null),
          ),
        ),
      ),
    );
  }
}
