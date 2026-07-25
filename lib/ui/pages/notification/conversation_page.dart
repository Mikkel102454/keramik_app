import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/ui/pages/notification/add_group_members_page.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page_controller.dart';
import 'package:ceramic_app/ui/pages/notification/report_message_page.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:intl/intl.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({required this.initialConversation, super.key});
  final DirectConversationDto initialConversation;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late final ConversationPageController _controller =
      ConversationPageController(widget.initialConversation);
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_showControllerError);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_showControllerError);
    _controller.dispose();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? _lastError;
  void _showControllerError() {
    final error = _controller.error;
    if (!mounted || error == null || error == _lastError) return;
    _lastError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });
  }

  Future<void> _send() async {
    final sent = await _controller.send(_composer.text);
    if (!mounted || !sent) return;
    _composer.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _comingLater() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.comingLater)));
  }

  Future<void> _archive() async {
    try {
      await _controller.archive();
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$exception')));
      }
    }
  }

  Future<void> _renameGroup() async {
    final name = TextEditingController(text: _controller.conversation.title);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.renameGroup),
        content: TextField(controller: name, autofocus: true, maxLength: 100),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    name.dispose();
    if (value == null || value.isEmpty) return;
    try {
      await ChatRepository.renameGroup(_controller.conversation.id, value);
      await _controller.load();
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$exception')));
      }
    }
  }

  Future<void> _addMembers() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddGroupMembersPage(group: _controller.conversation),
      ),
    );
    if (changed == true) await _controller.load();
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.leaveGroupQuestion),
        content: Text(context.l10n.leaveGroupExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.leave),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ChatRepository.leaveGroup(_controller.conversation.id);
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$exception')));
      }
    }
  }

  Future<void> _showMessageActions(ChatMessageDto message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(context.l10n.reportMessage),
          onTap: () => Navigator.pop(context, 'report'),
        ),
      ),
    );
    if (!mounted || action != 'report') return;
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportMessagePage(
          conversationId: _controller.conversation.id,
          message: message,
        ),
      ),
    );
    if (mounted && submitted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reportSubmitted)),
      );
    }
  }

  void _selectMenu(String value) {
    switch (value) {
      case 'rename':
        _renameGroup();
        return;
      case 'members':
        _addMembers();
        return;
      case 'leave':
        _leaveGroup();
        return;
      case 'archive':
        _archive();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final conversation = _controller.conversation;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                ProfileAvatar(
                  initials: conversation.avatarInitials,
                  colorHex: conversation.avatarColor,
                  imageUrl: conversation.otherUser?.avatarUrl,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        conversation.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (conversation.type == 'GROUP')
                        Text(
                          context.l10n.memberCount(conversation.memberCount),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: _selectMenu,
                itemBuilder: (_) => [
                  if (conversation.type == 'GROUP' &&
                      !conversation.readOnly) ...[
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(context.l10n.renameGroup),
                    ),
                    PopupMenuItem(
                      value: 'members',
                      child: Text(context.l10n.addMembers),
                    ),
                    PopupMenuItem(
                      value: 'leave',
                      child: Text(context.l10n.leaveGroup),
                    ),
                  ],
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(context.l10n.archiveChat),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _messageBody()),
              if (conversation.readOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Text(
                    conversation.readOnlyReason ??
                        context.l10n.conversationReadOnly,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                _Composer(
                  controller: _composer,
                  sending: _controller.isSending,
                  onSend: _send,
                  onFutureFeature: _comingLater,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _messageBody() {
    if (_controller.isLoading && _controller.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null && _controller.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_controller.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _controller.load,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }
    if (_controller.messages.isEmpty) {
      return Center(
        child: Text(
          context.l10n.startConversation,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount:
            _controller.messages.length +
            (_controller.beforeCursor == null ? 0 : 1),
        itemBuilder: (context, index) {
          if (_controller.beforeCursor != null && index == 0) {
            return Center(
              child: TextButton(
                onPressed: _controller.isLoadingOlder
                    ? null
                    : _controller.loadOlder,
                child: Text(
                  _controller.isLoadingOlder
                      ? context.l10n.loading
                      : context.l10n.loadEarlierMessages,
                ),
              ),
            );
          }
          final offset = _controller.beforeCursor == null ? 0 : 1;
          final messageIndex = index - offset;
          final message = _controller.messages[messageIndex];
          final previous = messageIndex == 0
              ? null
              : _controller.messages[messageIndex - 1];
          final showDay =
              previous == null ||
              !_sameDay(previous.createdAt, message.createdAt);
          return Column(
            children: [
              if (showDay) _DateSeparator(date: message.createdAt),
              _MessageBubble(
                message: message,
                isGroup: _controller.conversation.type == 'GROUP',
                onLongPress: !message.mine && message.type == 'TEXT'
                    ? () => _showMessageActions(message)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isGroup,
    this.onLongPress,
  });
  final ChatMessageDto message;
  final bool isGroup;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (message.type == 'SYSTEM') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 20),
        child: Text(
          message.body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Semantics(
      button: onLongPress != null,
      hint: onLongPress == null
          ? null
          : context.l10n.messageActionsHint,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Align(
          alignment: message.mine
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * .76,
            ),
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: message.mine
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomRight: message.mine ? const Radius.circular(5) : null,
                bottomLeft: message.mine ? null : const Radius.circular(5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGroup && !message.mine && message.senderUsername != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      message.senderUsername!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  message.body,
                  style: TextStyle(
                    color: message.mine
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today =
        now.year == date.year && now.month == date.month && now.day == date.day;
    final label = today
        ? context.l10n.today
        : DateFormat.yMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onFutureFeature,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onFutureFeature;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: context.l10n.voiceMessageComingLater,
              onPressed: onFutureFeature,
              icon: const Icon(Icons.mic_none),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: context.l10n.messageHint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: context.l10n.emojiComingLater,
                        onPressed: onFutureFeature,
                        icon: const Icon(
                          Icons.sentiment_satisfied_alt_outlined,
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.imageComingLater,
                        onPressed: onFutureFeature,
                        icon: const Icon(Icons.image_outlined),
                      ),
                    ],
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              tooltip: context.l10n.send,
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
