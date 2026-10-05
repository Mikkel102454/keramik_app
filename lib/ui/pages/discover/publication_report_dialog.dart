import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

class PublicationReportDraft {
  const PublicationReportDraft(this.category, this.explanation);

  final String category;
  final String explanation;
}

Future<PublicationReportDraft?> showPublicationReportDialog(
  BuildContext context,
) => showDialog<PublicationReportDraft>(
  context: context,
  builder: (_) => const _PublicationReportDialog(),
);

class _PublicationReportDialog extends StatefulWidget {
  const _PublicationReportDialog();

  @override
  State<_PublicationReportDialog> createState() =>
      _PublicationReportDialogState();
}

class _PublicationReportDialogState extends State<_PublicationReportDialog> {
  final _explanation = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _category = 'SPAM';

  @override
  void dispose() {
    _explanation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.reportPublication),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.publicationReportEvidenceDisclosure,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.l10n.reportReason),
              items:
                  const [
                        'SPAM',
                        'HARASSMENT_OR_HATE',
                        'SEXUAL_CONTENT',
                        'VIOLENCE_OR_DANGEROUS',
                        'STOLEN_WORK_OR_IP',
                        'OTHER',
                      ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            context.l10n.publicationReportCategory(value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() => _category = value ?? _category);
              },
            ),
            TextFormField(
              controller: _explanation,
              maxLength: 2000,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.l10n.reportExplanation,
              ),
              validator: (value) {
                final length = value?.trim().runes.length ?? 0;
                final required =
                    _category == 'STOLEN_WORK_OR_IP' || _category == 'OTHER';
                if ((required && length < 10) ||
                    (length > 0 && length < 10) ||
                    length > 2000) {
                  return context.l10n.reportOtherExplanationRequired;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() == true) {
            Navigator.pop(
              context,
              PublicationReportDraft(_category, _explanation.text.trim()),
            );
          }
        },
        child: Text(context.l10n.submitReport),
      ),
    ],
  );
}
