import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Caller-owned draft; successful sends clear it in the page/controller layer.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onEmoji,
    this.onVoice,
    this.onImage,
    this.onCeramic,
    this.voiceBar,
    this.onVoiceHold,
    this.onVoiceRelease,
    this.onVoiceCancel,
    this.onVoiceLock,
    this.onVoiceCancelArmed,
    this.onCamera,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onEmoji;
  final VoidCallback? onVoice;
  final VoidCallback? onImage;
  final VoidCallback? onCeramic;
  final VoidCallback? onCamera;
  final Widget? voiceBar;
  final VoidCallback? onVoiceHold;
  final VoidCallback? onVoiceRelease;
  final VoidCallback? onVoiceCancel;
  final VoidCallback? onVoiceLock;
  final ValueChanged<bool>? onVoiceCancelArmed;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  Offset? _voiceOrigin;
  int? _pointer;
  bool _cancelArmed = false;

  // This listener stays mounted when the recording bar replaces the input.
  // The microphone's recognizer may then disappear, but pointer up still arrives.
  void _move(PointerMoveEvent event) {
    final origin = _voiceOrigin;
    if (origin == null || event.pointer != _pointer) return;
    final delta = event.position - origin;
    final armed = delta.dx < -80;
    if (armed != _cancelArmed) {
      _cancelArmed = armed;
      widget.onVoiceCancelArmed?.call(armed);
    }
    if (!armed && delta.dy < -70) {
      _voiceOrigin = null;
      widget.onVoiceLock?.call();
    }
  }

  void _up(PointerEvent event, {bool cancelled = false}) {
    if (event.pointer != _pointer) return;
    final held = _voiceOrigin != null;
    final discard = cancelled || _cancelArmed;
    _voiceOrigin = null;
    _pointer = null;
    _cancelArmed = false;
    if (held) {
      if (discard) {
        widget.onVoiceCancel?.call();
      } else {
        widget.onVoiceRelease?.call();
      }
    }
  }

  TextEditingController get controller => widget.controller;
  bool get sending => widget.sending;
  VoidCallback get onSend => widget.onSend;
  VoidCallback get onEmoji => widget.onEmoji;
  VoidCallback? get onVoice => widget.onVoice;
  VoidCallback? get onImage => widget.onImage;
  VoidCallback? get onCeramic => widget.onCeramic;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (event) => _pointer ??= event.pointer,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: (event) => _up(event, cancelled: true),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child:
            widget.voiceBar ??
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final hasText = value.text.isNotEmpty;
                final canSend = !sending && value.text.trim().isNotEmpty;
                final colors = Theme.of(context).colorScheme;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.onCamera != null && !hasText)
                      IconButton(
                        tooltip: context.l10n.camera,
                        onPressed: sending ? null : widget.onCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  minLines: 1,
                                  maxLines: 5,
                                  // Keep the input connection/focus while preventing edits
                                  // during a send; readOnly would hide the keyboard.
                                  inputFormatters: [
                                    TextInputFormatter.withFunction(
                                      (oldValue, newValue) =>
                                          sending ||
                                              newValue.text.runes.length > 2000
                                          ? oldValue
                                          : newValue,
                                    ),
                                  ],
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: context.l10n.messageHint,
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onSubmitted: (_) {
                                    if (canSend) onSend();
                                  },
                                ),
                              ),
                              if (!hasText && !sending) ...[
                                GestureDetector(
                                  excludeFromSemantics: true,
                                  onLongPressStart:
                                      sending ||
                                          onVoice == null ||
                                          widget.onVoiceHold == null
                                      ? null
                                      : (details) {
                                          _cancelArmed = false;
                                          _voiceOrigin = details.globalPosition;
                                          widget.onVoiceHold!();
                                        },
                                  child: Semantics(
                                    label: context.l10n.voiceMessage,
                                    hint: context.l10n.voiceRecordingHint,
                                    child: IconButton(
                                      // Tooltip's long-press recognizer would
                                      // otherwise consume the recording hold.
                                      onPressed: onVoice,
                                      icon: const Icon(Icons.mic_none),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: context.l10n.chatImage,
                                  onPressed: onImage,
                                  icon: const Icon(Icons.photo_outlined),
                                ),
                              ],
                              IconButton(
                                tooltip: context.l10n.emojiPicker,
                                onPressed: sending ? null : onEmoji,
                                icon: const Icon(
                                  Icons.sentiment_satisfied_alt_outlined,
                                ),
                              ),
                              IconButton(
                                tooltip: context.l10n.shareCeramic,
                                onPressed: sending ? null : onCeramic,
                                icon: const Icon(Icons.handyman_outlined),
                              ),
                              if (hasText || sending)
                                IconButton(
                                  tooltip: context.l10n.send,
                                  onPressed: canSend ? onSend : null,
                                  color: colors.primary,
                                  icon: sending
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    ),
  );
}
