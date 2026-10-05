import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:clay_dock/app/chat_media_controller.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';

class ChatAttachment extends StatefulWidget {
  const ChatAttachment({
    super.key,
    required this.conversation,
    required this.message,
    this.loadFile,
  });
  final String conversation;
  final ChatMessageDto message;

  /// A prepared local send can supply its private file until acknowledged.
  final Future<File> Function()? loadFile;
  @override
  State<ChatAttachment> createState() => _ChatAttachmentState();
}

class _ChatAttachmentState extends State<ChatAttachment> {
  late Future<File> _download = _fetch();

  Future<File> _fetch() =>
      widget.loadFile?.call() ??
      ChatMediaDownload.fetch(
        widget.conversation,
        widget.message.id,
        widget.message.type,
      );

  void _retry() => setState(() {
    _download = _fetch();
  });

  void _openImage(File file) {
    ChatPlaybackController.instance.pause();
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  semanticLabel: context.l10n.chatImage,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: context.l10n.close,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File>(
    future: _download,
    builder: (context, snapshot) {
      final colors = Theme.of(context).colorScheme;
      final file = snapshot.data;
      final loading = file == null && !snapshot.hasError;
      if (widget.message.type == 'IMAGE') {
        return LayoutBuilder(
          builder: (context, constraints) {
            final attachment = widget.message.attachment!;
            final ratio =
                math.max(1, attachment.width ?? 1) /
                math.max(1, attachment.height ?? 1);
            final width = math.min(250.0, constraints.maxWidth);
            final height = math.min(340.0, width / ratio);
            return ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                key: ValueKey('chat-photo-${widget.message.id}'),
                width: math.min(width, height * ratio),
                height: height,
                child: loading
                    ? ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : snapshot.hasError
                    ? ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.l10n.attachmentUnavailable),
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () => _openImage(file),
                        child: Image.file(
                          file!,
                          fit: BoxFit.contain,
                          semanticLabel: context.l10n.chatImage,
                          errorBuilder: (_, _, _) => Center(
                            child: TextButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh),
                              label: Text(context.l10n.attachmentUnavailable),
                            ),
                          ),
                        ),
                      ),
              ),
            );
          },
        );
      }
      return AnimatedBuilder(
        animation: ChatPlaybackController.instance,
        builder: (context, _) {
          final playback = ChatPlaybackController.instance;
          final playing =
              file != null && playback.playing && playback.path == file.path;
          return VoiceMessagePill(
            mine: widget.message.mine,
            durationMs: widget.message.attachment?.durationMs ?? 0,
            playing: playing,
            loading: loading,
            error: snapshot.hasError,
            onPressed: loading
                ? null
                : snapshot.hasError
                ? _retry
                : () async {
                    try {
                      await playback.toggle(file!);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.attachmentUnavailable),
                          ),
                        );
                      }
                    }
                  },
          );
        },
      );
    },
  );
}

/// Decorative bars convey audio content; they do not represent a waveform.
class VoiceMessagePill extends StatelessWidget {
  const VoiceMessagePill({
    super.key,
    required this.mine,
    required this.durationMs,
    required this.onPressed,
    this.playing = false,
    this.loading = false,
    this.error = false,
  });
  final bool mine;
  final int durationMs;
  final VoidCallback? onPressed;
  final bool playing;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = mine ? colors.onPrimary : colors.onSurface;
    final seconds = (math.max(0, durationMs) / 1000).round();
    final duration =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    final action = error
        ? context.l10n.attachmentUnavailable
        : playing
        ? context.l10n.pauseVoiceMessage
        : context.l10n.playVoiceMessage;
    // Match the text bubble's single line and its 10px vertical padding.
    final textStyle = DefaultTextStyle.of(context).style.copyWith(height: 1.25);
    final line = TextPainter(
      text: TextSpan(text: duration, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final controlSize = line.height + 12;
    line.dispose();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: mine ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: action,
              onPressed: onPressed,
              style: IconButton.styleFrom(
                minimumSize: Size.square(controlSize),
                maximumSize: Size.square(controlSize),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: Colors.transparent,
                backgroundColor: ink,
                foregroundColor: mine
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                disabledBackgroundColor: ink,
              ),
              icon: loading
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: mine ? colors.primary : colors.onSurface,
                      ),
                    )
                  : Icon(
                      error
                          ? Icons.refresh
                          : playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final height in [6.0, 14.0, 22.0, 16.0, 10.0])
                    Container(
                      width: 3,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(duration, style: textStyle.copyWith(color: ink)),
            ),
          ],
        ),
      ),
    );
  }
}
