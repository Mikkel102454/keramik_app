import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class MessageRequestPage extends StatefulWidget {
  const MessageRequestPage({required this.user, super.key});
  final UserProfileDto user;

  @override
  State<MessageRequestPage> createState() => _MessageRequestPageState();
}

class _MessageRequestPageState extends State<MessageRequestPage> {
  final TextEditingController _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final conversation = await ChatRepository.createRequest(
        widget.user.userId,
        createClientUuid(),
        text,
      );
      if (mounted) Navigator.pop(context, conversation);
    } catch (exception) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$exception')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.messageUser(widget.user.username)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.messageRequestPreviewExplanation,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _message,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: context.l10n.writeMessageRequest,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(context.l10n.sendRequest),
            ),
          ],
        ),
      ),
    );
  }
}
