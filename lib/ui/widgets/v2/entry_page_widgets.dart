import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'form_field_style.dart';
import 'studio_widgets.dart';

Future<bool> confirmEntryDiscard(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(context.l10n.notebookDraftDiscard),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    ) ==
    true;

/// Common create/view/edit shell for private material and notebook entries.
class EntryPage extends StatelessWidget {
  const EntryPage({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
    this.onSave,
    this.onEdit,
    this.onDelete,
    this.onRefresh,
    this.onRetry,
    this.busy = false,
    this.error,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack, onSave, onEdit, onDelete, onRetry;
  final Future<void> Function()? onRefresh;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    Widget content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: Text(context.l10n.retry),
                  ),
              ],
            ),
          ),
        ...children,
        const SizedBox(height: 32),
      ],
    );
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: busy ? null : onBack,
                icon: const BackButtonIcon(),
              ),
        actions: [
          if (onSave != null)
            IconButton(
              tooltip: context.l10n.save,
              onPressed: busy ? null : onSave,
              icon: const Icon(Icons.check),
            ),
          if (onEdit != null)
            IconButton(
              tooltip: context.l10n.edit,
              onPressed: busy ? null : onEdit,
              icon: const Icon(Icons.edit),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: context.l10n.delete,
              onPressed: busy ? null : onDelete,
              color: Theme.of(context).colorScheme.error,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StudioContent(
          maxWidth: StudioSpacing.formWidth,
          child: AbsorbPointer(absorbing: busy, child: content),
        ),
      ),
    );
  }
}

class EntrySection extends StatelessWidget {
  const EntrySection({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: StudioSpacing.section),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioSectionHeading(title: title),
        StudioSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class EntryValue extends StatelessWidget {
  const EntryValue({
    super.key,
    required this.label,
    required this.value,
    this.selectable = false,
  });
  final String label, value;
  final bool selectable;

  @override
  Widget build(BuildContext context) => FieldLabel(
    label: label,
    child: Container(
      width: double.infinity,
      padding: FormFieldStyle.padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(FormFieldStyle.radius),
      ),
      child: selectable
          ? SelectableText(
              value.isEmpty ? context.l10n.notSet : value,
              style: FormFieldStyle.textStyle,
            )
          : Text(
              value.isEmpty ? context.l10n.notSet : value,
              style: FormFieldStyle.textStyle,
            ),
    ),
  );
}
