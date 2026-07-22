import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/chat_report_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:flutter/material.dart';

typedef SubmitChatReport =
    Future<ChatReportReceiptDto> Function({
      required String conversationId,
      required String messageId,
      required ChatReportCategory category,
      String? explanation,
    });

class ReportMessagePage extends StatefulWidget {
  const ReportMessagePage({
    required this.conversationId,
    required this.message,
    this.submitReport,
    super.key,
  });

  final String conversationId;
  final ChatMessageDto message;
  final SubmitChatReport? submitReport;

  @override
  State<ReportMessagePage> createState() => _ReportMessagePageState();
}

class _ReportMessagePageState extends State<ReportMessagePage> {
  final TextEditingController _explanation = TextEditingController();
  ChatReportCategory? _category;
  String? _validationError;
  String? _submitError;
  bool _submitting = false;

  @override
  void dispose() {
    _explanation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final validation = validateChatReport(_category, _explanation.text);
    setState(() {
      _validationError = validation;
      _submitError = null;
    });
    if (validation != null) return;

    setState(() => _submitting = true);
    try {
      final submit = widget.submitReport ?? ChatRepository.reportMessage;
      final trimmed = _explanation.text.trim();
      await submit(
        conversationId: widget.conversationId,
        messageId: widget.message.id,
        category: _category!,
        explanation: trimmed.isEmpty ? null : trimmed,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) setState(() => _submitError = exception.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report message')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Why are you reporting this message?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ChatReportCategory.values
                  .map(
                    (category) => ChoiceChip(
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) => setState(() {
                        _category = category;
                        _validationError = null;
                      }),
                    ),
                  )
                  .toList(),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _explanation,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Explanation (optional)',
                hintText: 'Add details that may help a future review.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xfff2f2f2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message being reported',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.message.body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The selected message and up to two nearby messages on each side '
              'will be securely included for review. Reporting does not block '
              'this account or change the conversation.',
              style: TextStyle(color: Colors.black54, height: 1.35),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit report'),
            ),
          ],
        ),
      ),
    );
  }
}
