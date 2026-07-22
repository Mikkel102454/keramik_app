import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/ui/pages/notification/add_group_members_page.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page_controller.dart';
import 'package:ceramic_app/ui/pages/notification/report_message_page.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

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
    ).showSnackBar(const SnackBar(content: Text('Coming later')));
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
        title: const Text('Rename group'),
        content: TextField(controller: name, autofocus: true, maxLength: 100),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.text.trim()),
            child: const Text('Save'),
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
        title: const Text('Leave group?'),
        content: const Text(
          'You will keep read-only history from your membership periods.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
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
          title: const Text('Report message'),
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
        const SnackBar(
          content: Text('Report submitted. Blocking is a separate action.'),
        ),
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
                          '${conversation.memberCount} members',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
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
                      !conversation.readOnly) ...const [
                    PopupMenuItem(value: 'rename', child: Text('Rename group')),
                    PopupMenuItem(value: 'members', child: Text('Add members')),
                    PopupMenuItem(value: 'leave', child: Text('Leave group')),
                  ],
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Archive chat'),
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
                  color: const Color(0xfff2f2f2),
                  child: Text(
                    conversation.readOnlyReason ??
                        'This conversation is read-only.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
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
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_controller.messages.isEmpty) {
      return const Center(
        child: Text(
          'Start the conversation.',
          style: TextStyle(color: Colors.black45),
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
                      ? 'Loading…'
                      : 'Load earlier messages',
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
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      );
    }
    return Semantics(
      button: onLongPress != null,
      hint: onLongPress == null ? null : 'Long-press for message actions',
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
              color: message.mine ? Colors.black : const Color(0xffeeeeee),
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  message.body,
                  style: TextStyle(
                    color: message.mine ? Colors.white : Colors.black,
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
        ? 'Today'
        : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black45),
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
              tooltip: 'Voice message — coming later',
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
                  hintText: 'Message…',
                  filled: true,
                  fillColor: const Color(0xfff2f2f2),
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
                        tooltip: 'Emoji — coming later',
                        onPressed: onFutureFeature,
                        icon: const Icon(
                          Icons.sentiment_satisfied_alt_outlined,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Image — coming later',
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
              tooltip: 'Send',
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
