import 'package:ceramic_app/app/chat_media_controller.dart';
import 'package:ceramic_app/app/chat_voice_draft_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/ui/widgets/chat_attachment.dart';
import 'package:flutter/material.dart';

class ChatVoiceComposer extends StatelessWidget {
  const ChatVoiceComposer({
    super.key,
    required this.controller,
    required this.canSend,
  });
  final ChatVoiceDraftController controller;
  final bool canSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final phase = controller.phase;
    final busy =
        phase == VoiceDraftPhase.starting ||
        phase == VoiceDraftPhase.stopping ||
        phase == VoiceDraftPhase.sending;
    final seconds = controller.duration.inSeconds;
    final duration =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              controller.error == VoiceDraftError.recording
                  ? context.l10n.voiceRecordingFailed
                  : controller.sendTimedOut
                  ? context.l10n.requestTimedOut
                  : context.l10n.chatMediaFailed,
            ),
          ),
        if (controller.recording)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              controller.locked
                  ? context.l10n.voiceRecordingLocked
                  : context.l10n.voiceRecordingHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (controller.recording && !controller.locked)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 14, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open_outlined),
                  const Icon(Icons.keyboard_arrow_up),
                  Text(
                    context.l10n.voiceSlideToLock,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.l10n.cancel,
                  onPressed: phase == VoiceDraftPhase.sending
                      ? null
                      : () async {
                          await ChatPlaybackController.instance.pause();
                          await controller.cancel();
                        },
                  color: colors.error,
                  icon: _RecordingTrash(open: controller.cancelArmed),
                ),
                if (busy)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (controller.recording) ...[
                  Icon(Icons.circle, color: colors.error, size: 8),
                  const SizedBox(width: 8),
                  Text(duration),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child:
                      phase == VoiceDraftPhase.preview &&
                          controller.file != null
                      ? AnimatedBuilder(
                          animation: ChatPlaybackController.instance,
                          builder: (context, _) => VoiceMessagePill(
                            mine: false,
                            durationMs: controller.duration.inMilliseconds,
                            playing:
                                ChatPlaybackController.instance.playing &&
                                ChatPlaybackController.instance.path ==
                                    controller.file!.path,
                            onPressed: () async {
                              try {
                                await ChatPlaybackController.instance.toggle(
                                  controller.file!,
                                );
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.attachmentUnavailable,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        )
                      : Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                          controller.recording
                              ? controller.cancelArmed
                                    ? context.l10n.cancel
                                    : controller.locked
                                    ? context.l10n.recording
                                    : context.l10n.voiceSlideToCancel
                              : context.l10n.voiceMessage,
                        ),
                ),
                IconButton(
                  tooltip: controller.recording
                      ? controller.locked
                            ? context.l10n.stopRecording
                            : context.l10n.voiceMessage
                      : phase == VoiceDraftPhase.idle
                      ? context.l10n.recordVoice
                      : context.l10n.send,
                  onPressed: busy
                      ? null
                      : controller.recording
                      ? controller.locked
                            ? controller.finishRecording
                            : null
                      : phase == VoiceDraftPhase.idle
                      ? canSend
                            ? () => controller.start(lock: true)
                            : null
                      : canSend
                      ? () async {
                          await ChatPlaybackController.instance.pause();
                          await controller.send();
                        }
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: controller.cancelArmed
                        ? colors.error
                        : colors.primary,
                    foregroundColor: colors.onPrimary,
                    disabledBackgroundColor: controller.cancelArmed
                        ? colors.error
                        : colors.primary,
                  ),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: controller.cancelArmed
                        ? const _RecordingTrash(
                            key: ValueKey('voice-cancel-armed'),
                            open: true,
                          )
                        : Icon(
                            key: const ValueKey('voice-record-action'),
                            controller.recording
                                ? controller.locked
                                      ? Icons.stop
                                      : Icons.mic
                                : phase == VoiceDraftPhase.idle
                                ? Icons.mic
                                : Icons.send,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Animate the lid separately so cancel readiness is visible before release.
class _RecordingTrash extends StatelessWidget {
  const _RecordingTrash({super.key, required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 1 : 0),
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    builder: (context, progress, _) => SizedBox.square(
      dimension: 24,
      child: CustomPaint(
        painter: _TrashPainter(
          progress,
          IconTheme.of(context).color ??
              Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

class _TrashPainter extends CustomPainter {
  _TrashPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(7, 21)
        ..lineTo(17, 21)
        ..lineTo(18, 9),
      ink,
    );
    canvas.drawLine(const Offset(10, 11), const Offset(10, 18), ink);
    canvas.drawLine(const Offset(14, 11), const Offset(14, 18), ink);
    canvas.save();
    canvas.translate(5, 6 - 3 * progress);
    canvas.rotate(-0.45 * progress);
    canvas.drawLine(Offset.zero, const Offset(14, 0), ink);
    canvas.drawPath(
      Path()
        ..moveTo(4, 0)
        ..lineTo(4, -2)
        ..lineTo(10, -2)
        ..lineTo(10, 0),
      ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrashPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
