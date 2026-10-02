import 'package:flutter/material.dart';
import 'form_field_style.dart';

/// Controlled selection, including a nullable "not set" item when supplied.
class SelectFieldWidget<T> extends StatefulWidget {
  const SelectFieldWidget({
    super.key,
    this.label,
    this.placeholder,
    this.value,
    required this.items,
    required this.onChanged,
  });
  final String? label;
  final String? placeholder;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  State<SelectFieldWidget<T>> createState() => _SelectFieldWidgetState<T>();
}

class _SelectFieldWidgetState<T> extends State<SelectFieldWidget<T>> {
  final _field = GlobalKey<FormFieldState<T>>();

  @override
  void didUpdateWidget(covariant SelectFieldWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An async rejection can return to the old value before an intermediate
    // build. Reconcile the FormField's optimistic selection with its owner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _field.currentState?.value != widget.value) {
        _field.currentState?.didChange(widget.value);
      }
    });
  }

  @override
  Widget build(BuildContext context) => FieldLabel(
    label: widget.label,
    child: DropdownButtonFormField<T>(
      key: _field,
      initialValue: widget.value,
      isExpanded: true,
      style: FormFieldStyle.textStyle.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: FormFieldStyle.decoration(
        context,
        hint: widget.placeholder ?? widget.label,
      ),
      hint: Text(widget.placeholder ?? widget.label ?? ''),
      items: widget.items,
      onChanged: widget.onChanged,
      selectedItemBuilder: (_) => [
        for (final item in widget.items)
          Align(alignment: Alignment.centerLeft, child: item.child),
      ],
    ),
  );
}
