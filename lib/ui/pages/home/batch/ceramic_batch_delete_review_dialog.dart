import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/ceramic_batch_delete_dto.dart';
import 'package:flutter/material.dart';

class CeramicBatchDeleteReviewDialog extends StatefulWidget {
  const CeramicBatchDeleteReviewDialog({
    super.key,
    required this.preview,
  });

  final CeramicBatchDeletePreviewDto preview;

  @override
  State<CeramicBatchDeleteReviewDialog> createState() =>
      _CeramicBatchDeleteReviewDialogState();
}

class _CeramicBatchDeleteReviewDialogState
    extends State<CeramicBatchDeleteReviewDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.sizeOf(context).height * .55;
    final contentHeight = availableHeight.clamp(260.0, 460.0).toDouble();
    return AlertDialog(
      title: Text(context.l10n.reviewBatchDelete),
      content: SizedBox(
        width: 520,
        height: contentHeight,
        child: ListView(
          children: [
            Text(
              context.l10n.batchDeleteTargetCount(
                widget.preview.selectedCount,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(context.l10n.batchDeleteWarning),
            const SizedBox(height: 16),
            ...widget.preview.targets.map(
              (target) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline),
                title: Text(target.title),
              ),
            ),
            const Divider(height: 28),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acknowledged,
              onChanged: (value) =>
                  setState(() => _acknowledged = value ?? false),
              title: Text(context.l10n.understandPermanentDeletion),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _acknowledged
              ? () => Navigator.pop(context, true)
              : null,
          icon: const Icon(Icons.delete_forever),
          label: Text(
            context.l10n.deleteSelectedCeramics(
              widget.preview.selectedCount,
            ),
          ),
        ),
      ],
    );
  }
}
