import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ceramic_app/app/chat_image_preparation.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class ChatImageDraft {
  const ChatImageDraft(this.file, this.clientId, this.attachment);
  final File file;
  final String clientId;
  final ChatAttachmentDto attachment;
}

/// System photo-grid/camera selection followed by one retained image preview.
class ChatMediaDraft extends StatefulWidget {
  const ChatMediaDraft({
    super.key,
    required this.conversation,
    required this.source,
    this.pickImage,
    this.upload,
    this.onQueue,
  });
  final String conversation;
  final ImageSource source;
  @visibleForTesting
  final Future<File?> Function(ImageSource)? pickImage;
  @visibleForTesting
  final Future<ChatMessageDto> Function(File, String)? upload;

  /// Transfers the prepared private file to the conversation's local send.
  final ValueChanged<ChatImageDraft>? onQueue;
  @override
  State<ChatMediaDraft> createState() => _ChatMediaDraftState();
}

class _ChatMediaDraftState extends State<ChatMediaDraft> {
  String _clientId = createClientUuid();
  File? _file;
  bool _sending = false;
  bool _working = true;
  bool _error = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_pick());
    });
  }

  @override
  void dispose() {
    if (!_sending) unawaited(_delete(_file));
    super.dispose();
  }

  Future<void> _delete(File? file) async {
    try {
      await file?.delete();
    } catch (_) {
      /* Startup recovery retries. */
    }
  }

  Future<void> _pick() async {
    if (_sending) return;
    setState(() {
      _working = true;
      _error = false;
    });
    try {
      final file = await (widget.pickImage ?? ChatImagePreparation.pick)(
        widget.source,
      );
      if (!mounted) {
        await _delete(file);
        return;
      }
      if (file == null) {
        if (_file == null) Navigator.pop(context);
        return;
      }
      final previous = _file;
      _file = file;
      _clientId = createClientUuid();
      if (previous?.path != file.path) {
        await _delete(previous);
      }
    } catch (_) {
      _error = true;
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final file = _file;
    if (file == null || _working || _sending) return;
    setState(() {
      _sending = true;
      _error = false;
    });
    try {
      if (widget.onQueue != null) {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        late ChatAttachmentDto attachment;
        try {
          final frame = await codec.getNextFrame();
          attachment = ChatAttachmentDto(
            type: 'IMAGE',
            size: bytes.length,
            width: frame.image.width,
            height: frame.image.height,
          );
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
        if (!mounted) {
          await _delete(file);
          return;
        }
        widget.onQueue!(ChatImageDraft(file, _clientId, attachment));
        _file = null;
        _done = true;
        Navigator.pop(context);
        return;
      }
      final sent =
          await (widget.upload?.call(file, _clientId) ??
              ChatRepository.sendAttachment(
                widget.conversation,
                _clientId,
                'IMAGE',
                file,
              ));
      _done = true;
      await _delete(file);
      if (mounted) Navigator.pop(context, sent);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = true;
        });
      } else {
        await _delete(file);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_sending || _done,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.close,
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.chatImage,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: widget.source == ImageSource.camera
                        ? context.l10n.camera
                        : context.l10n.gallery,
                    onPressed: _sending || _working ? null : _pick,
                    icon: Icon(
                      widget.source == ImageSource.camera
                          ? Icons.camera_alt_outlined
                          : Icons.photo_library_outlined,
                    ),
                  ),
                ],
              ),
              if (_working || _sending) const LinearProgressIndicator(),
              if (_error)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(context.l10n.chatMediaFailed),
                ),
              if (_file != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .5,
                      ),
                      child: Image.file(
                        _file!,
                        fit: BoxFit.contain,
                        semanticLabel: context.l10n.chatImage,
                      ),
                    ),
                  ),
                ),
              Text(
                context.l10n.chatImageLimit,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    child: Text(context.l10n.cancel),
                  ),
                  FilledButton.icon(
                    onPressed: _sending || _working || _file == null
                        ? null
                        : _send,
                    icon: _sending
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(context.l10n.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
