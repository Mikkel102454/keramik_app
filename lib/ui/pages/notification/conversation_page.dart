import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:ceramic_app/app/chat_voice_draft_controller.dart';
import 'package:ceramic_app/ui/widgets/chat_voice_composer.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:ceramic_app/ui/widgets/v2/ui_library.dart';
import 'package:ceramic_app/utils/emoji_insertion.dart';
import 'package:ceramic_app/ui/pages/notification/chat_media_draft.dart';
import 'package:ceramic_app/ui/widgets/chat_attachment.dart';
import 'package:ceramic_app/app/chat_media_controller.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/pages/profile/basic_profile_page.dart';
import 'package:ceramic_app/ui/pages/notification/add_group_members_page.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page_controller.dart';
import 'package:ceramic_app/ui/pages/notification/local_chat_send.dart';
import 'package:ceramic_app/ui/pages/notification/ceramic_sharing_pages.dart';
import 'package:ceramic_app/ui/pages/notification/report_message_page.dart';
import 'package:ceramic_app/ui/pages/notification/shared_ceramic_detail_page.dart';
import 'package:ceramic_app/ui/pages/discover/publication_detail_page.dart';
import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:ceramic_app/ui/widgets/chat_ceramic_card.dart';
import 'package:ceramic_app/ui/widgets/chat_publication_card.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:intl/intl.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    required this.initialConversation,
    this.controller,
    this.loadAttachment,
    super.key,
  });
  final DirectConversationDto initialConversation;

  /// The page owns disposal, including an injected test controller.
  @visibleForTesting
  final ConversationPageController? controller;
  @visibleForTesting
  final Future<File> Function(ChatMessageDto)? loadAttachment;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage>
    with WidgetsBindingObserver {
  late final ConversationPageController _controller =
      widget.controller ??
      ConversationPageController(widget.initialConversation);
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final ChatVoiceDraftController _voice = ChatVoiceDraftController(
    canSend: () =>
        _mediaAvailable &&
        _controller.conversation.canShare &&
        !_controller.isSending,
    isForeground: () =>
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    upload: (file, clientId) => _controller.sendAttachment(
      file,
      clientId,
      ChatAttachmentDto(
        type: 'VOICE',
        size: 0,
        durationMs: _voice.duration.inMilliseconds,
      ),
      retry: () => _voice.send(),
    ),
    onDiscard: _controller.removeLocalFile,
    onSent: (sent) {
      if (mounted) {
        unawaited(_controller.load());
      }
    },
  );
  late final Listenable _animations = Listenable.merge([_controller, _voice]);
  bool _mediaAvailable = false;
  bool _openingProfile = false;
  bool _changingRequest = false;
  int _lastSentRevision = 0;
  int _scrollRequest = 0;
  final Map<String, GlobalKey> _messageKeys = {};

  void _scrollAfterSend() {
    if (_lastSentRevision == _controller.sentRevision) {
      _preserveReadingPosition();
      return;
    }
    _lastSentRevision = _controller.sentRevision;
    _scrollToLatest();
  }

  void _scrollToLatest() {
    final request = ++_scrollRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || request != _scrollRequest || !_scroll.hasClients) return;
      // A reversed lazy list starts at the newest row without estimating the
      // height of older messages or building them to find the bottom.
      await _scroll.animateTo(
        _scroll.position.minScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _preserveReadingPosition() {
    if (!_scroll.hasClients ||
        _scroll.offset <= 1 ||
        _scroll.position.isScrollingNotifier.value) {
      return;
    }
    final viewport = _scroll.position.context.storageContext.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;
    final top = viewport.localToGlobal(Offset.zero).dy;
    final bottom = top + viewport.size.height;
    GlobalKey? anchor;
    double? anchorY;
    for (final key in _messageKeys.values) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y + box.size.height > top && y < bottom) {
        anchor = key;
        anchorY = y;
        break;
      }
    }
    if (anchor == null || anchorY == null) return;
    final request = _scrollRequest;
    final offset = _scroll.offset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          request != _scrollRequest ||
          !_scroll.hasClients ||
          (_scroll.offset - offset).abs() > 1 ||
          _scroll.position.isScrollingNotifier.value) {
        return;
      }
      final box = anchor!.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      final shift = anchorY! - box.localToGlobal(Offset.zero).dy;
      if (shift.abs() > 1) {
        _scroll.jumpTo(
          (_scroll.offset + shift).clamp(
            _scroll.position.minScrollExtent,
            _scroll.position.maxScrollExtent,
          ),
        );
      }
    });
  }

  Future<void> _openProfile(String userId) async {
    if (_openingProfile ||
        userId.isEmpty ||
        _voice.phase == VoiceDraftPhase.sending) {
      return;
    }
    _openingProfile = true;
    unawaited(ChatPlaybackController.instance.pause());
    try {
      await _voice.interrupt();
      final profile = await SocialRepository.getProfile(userId);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => BasicProfilePage(initialProfile: profile),
        ),
      );
      if (mounted) await _controller.load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.chatProfileUnavailable)),
        );
      }
    } finally {
      _openingProfile = false;
    }
  }

  Future<void> _changeRequest(bool accept) async {
    if (_changingRequest) return;
    setState(() => _changingRequest = true);
    try {
      if (accept) {
        await ChatRepository.accept(_controller.conversation.id);
      } else {
        await ChatRepository.decline(_controller.conversation.id);
      }
      if (mounted) await _controller.load();
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.operationFailed)));
      }
    } finally {
      if (mounted) setState(() => _changingRequest = false);
    }
  }

  String _readOnlyLabel(DirectConversationDto conversation) =>
      switch (conversation.status) {
        'PENDING' =>
          conversation.incomingRequest
              ? context.l10n.chatRequestAcceptToReply
              : context.l10n.chatRequestWaiting,
        'DECLINED' => context.l10n.chatRequestDeclined,
        'BLOCKED' => context.l10n.chatMessagingUnavailable,
        _ => conversation.readOnlyReason ?? context.l10n.conversationReadOnly,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_showControllerError);
    _controller.addListener(_checkVoiceAvailability);
    _lastSentRevision = _controller.sentRevision;
    _controller.addListener(_scrollAfterSend);
    _controller.load();
    ChatRepository.mediaAvailable()
        .then((available) {
          if (mounted) setState(() => _mediaAvailable = available);
        })
        .catchError((_) {
          /* Media stays unavailable. */
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_checkVoiceAvailability);
    _controller.removeListener(_showControllerError);
    _controller.removeListener(_scrollAfterSend);
    _voice.dispose();
    _controller.dispose();
    ChatPlaybackController.instance.pause();
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
        ).showSnackBar(SnackBar(content: Text(context.l10n.operationFailed)));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _voice.recording) {
      unawaited(_voice.interrupt());
    }
  }

  void _checkVoiceAvailability() {
    if (!_controller.conversation.canShare && _voice.recording) {
      unawaited(_voice.interrupt());
    }
  }

  void _startVoice({bool lock = false}) {
    if (!_mediaAvailable ||
        !_controller.conversation.canShare ||
        _controller.isSending) {
      return;
    }
    FocusScope.of(context).unfocus();
    unawaited(_voice.start(lock: lock));
  }

  Future<void> _media(ImageSource source) async {
    if (_voice.active ||
        !_mediaAvailable ||
        !_controller.conversation.canShare ||
        _controller.isSending) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ChatPlaybackController.instance.pause();
    if (!mounted) return;
    final sent = await showModalBottomSheet<ChatMessageDto>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ChatMediaDraft(
        conversation: _controller.conversation.id,
        source: source,
        onQueue: (draft) => unawaited(_queueImage(draft)),
      ),
    );
    if (sent != null && mounted) {
      _controller.recordSentMessage(sent);
      await _controller.load();
    }
  }

  Future<void> _queueImage(ChatImageDraft draft) async {
    try {
      await _controller.sendAttachment(
        draft.file,
        draft.clientId,
        draft.attachment,
        ownsFile: true,
      );
    } catch (_) {
      // Failure belongs to the retained message and its Retry action.
    }
  }

  Future<void> _emoji() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.emojiPicker),
            EmojiPicker(
              onEmojiSelected: (_, emoji) => _composer.value = insertChatEmoji(
                _composer.value,
                emoji.emoji,
              ),
              config: Config(
                locale: Localizations.localeOf(context),
                checkPlatformCompatibility: false,
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.SMILEYS,
                  recentTabBehavior: RecentTabBehavior.NONE,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                emojiViewConfig: EmojiViewConfig(
                  columns: 7,
                  recentsLimit: 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  enabled: false,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final sent = await _controller.send(_composer.text);
    if (!mounted || !sent) return;
    _composer.clear();
  }

  Future<void> _shareCeramic() async {
    ChatPlaybackController.instance.pause();
    final ceramic = await Navigator.push<CeramicDto>(
      context,
      MaterialPageRoute(builder: (_) => const CeramicPickerPage()),
    );
    if (!mounted ||
        ceramic == null ||
        !await confirmCeramicShare(
          context,
          checkMembership: !_controller.hasPendingCeramicSend(ceramic.id),
        )) {
      return;
    }
    final sent = await _controller.sendCeramic(
      ceramic.id,
      preview: ChatCeramicCardDto(
        available: true,
        title: ceramic.title,
        rating: ceramic.rating,
        imageUrl: ceramic.images.firstOrNull?.uri,
      ),
    );
    if (!mounted || !sent) return;
  }

  Future<void> _openCeramic(ChatMessageDto message) async {
    await _voice.interrupt();
    if (!mounted) return;
    ChatPlaybackController.instance.pause();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedCeramicDetailPage(
          conversationId: _controller.conversation.id,
          messageId: message.id,
        ),
      ),
    );
  }

  Future<void> _openPublication(ChatMessageDto message) async {
    await _voice.interrupt();
    if (!mounted) return;
    ChatPlaybackController.instance.pause();
    try {
      final detail = await ChatRepository.getSharedPublication(
        _controller.conversation.id,
        message.id,
      );
      if (!mounted) return;
      final parsed = PublicationDetailDto.fromJson(detail);
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PublicationDetailPage(
            publicationId: parsed.publicationId,
            initialDetail: parsed,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.publicationUnavailable)),
      );
    }
  }

  Future<void> _archive() async {
    try {
      await _controller.archive();
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.operationFailed)));
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
        ).showSnackBar(SnackBar(content: Text(context.l10n.operationFailed)));
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
        ).showSnackBar(SnackBar(content: Text(context.l10n.operationFailed)));
      }
    }
  }

  Future<void> _showMessageActions(ChatMessageDto message) async {
    await _voice.interrupt();
    if (!mounted) return;
    ChatPlaybackController.instance.pause();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.reportSubmitted)));
    }
  }

  void _selectMenu(String value) {
    ChatPlaybackController.instance.pause();
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
      animation: _animations,
      builder: (context, _) {
        final conversation = _controller.conversation;
        return PopScope(
          canPop: _voice.phase != VoiceDraftPhase.sending,
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: _chatTitle(conversation),
              actions: [
                if (!conversation.isDraft)
                  PopupMenuButton<String>(
                    enabled: !_voice.active,
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
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(child: _messageBody()),
                  if (conversation.incomingRequest)
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _controller.isLoading || _changingRequest
                              ? null
                              : () => _changeRequest(false),
                          child: Text(context.l10n.decline),
                        ),
                        FilledButton(
                          onPressed: _controller.isLoading || _changingRequest
                              ? null
                              : () => _changeRequest(true),
                          child: Text(context.l10n.accept),
                        ),
                      ],
                    ),
                  if (conversation.readOnly &&
                      !_controller.canRetryPendingText &&
                      !_voice.active)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: Text(
                        _readOnlyLabel(conversation),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    MessageComposer(
                      controller: _composer,
                      sending: _controller.isSending || _controller.isLoading,
                      onSend: _send,
                      onVoice: _mediaAvailable && conversation.canShare
                          ? () => _startVoice(lock: true)
                          : null,
                      onVoiceHold: () => _startVoice(),
                      onVoiceRelease: () => unawaited(_voice.release()),
                      onVoiceCancel: () => unawaited(_voice.cancel()),
                      onVoiceLock: _voice.lock,
                      onVoiceCancelArmed: _voice.armCancel,
                      voiceBar: _voice.active
                          ? ChatVoiceComposer(
                              controller: _voice,
                              canSend:
                                  _mediaAvailable &&
                                  conversation.canShare &&
                                  !_controller.isSending,
                            )
                          : null,
                      onCamera: _mediaAvailable && conversation.canShare
                          ? () => _media(ImageSource.camera)
                          : null,
                      onImage: _mediaAvailable && conversation.canShare
                          ? () => _media(ImageSource.gallery)
                          : null,
                      onEmoji: _emoji,
                      onCeramic: conversation.canShare && !conversation.archived
                          ? _shareCeramic
                          : null,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chatTitle(DirectConversationDto conversation) {
    final title = Row(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    );
    final user = conversation.otherUser;
    if (conversation.type != 'DIRECT' || user == null) return title;
    return Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('direct-chat-profile'),
        onTap: () => _openProfile(user.userId),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: title,
        ),
      ),
    );
  }

  Widget _messageBody() {
    final conversation = _controller.conversation;
    final messages = [
      ..._controller.messages,
      ..._controller.localSends.map((send) => send.message),
    ];
    final messageIndices = <Key, int>{
      for (var i = 0; i < messages.length; i++)
        ValueKey('chat-row-${messages[i].id}'): messages.length - 1 - i,
    };
    final messageIds = messages.map((message) => message.id).toSet();
    _messageKeys.removeWhere((id, _) => !messageIds.contains(id));
    final showGuidance =
        conversation.status == 'PENDING' &&
        !conversation.incomingRequest &&
        !conversation.readOnly;
    if (_controller.isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null && messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.operationFailed, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _controller.load,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }
    if (messages.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (showGuidance) _requestGuidance(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                context.l10n.startConversation,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              _controller.error == null &&
              (notification.scrollDelta ?? 0) > 0 &&
              notification.metrics.pixels > 0 &&
              notification.metrics.extentAfter < 200) {
            unawaited(_controller.loadOlder());
          }
          return false;
        },
        child: ListView.builder(
          controller: _scroll,
          reverse: true,
          findChildIndexCallback: (key) => messageIndices[key],
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount:
              messages.length +
              (showGuidance ? 1 : 0) +
              (_controller.beforeCursor == null ? 0 : 1),
          itemBuilder: (context, index) {
            if (showGuidance && index == messages.length) {
              return _requestGuidance();
            }
            if (index >= messages.length) {
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
            final messageIndex = messages.length - 1 - index;
            final message = messages[messageIndex];
            final localIndex = messageIndex - _controller.messages.length;
            final local = localIndex < 0
                ? null
                : _controller.localSends[localIndex];
            final senderId = conversation.type == 'DIRECT'
                ? conversation.otherUser?.userId
                : message.senderUserId;
            final previous = messageIndex == 0
                ? null
                : messages[messageIndex - 1];
            final showDay =
                previous == null ||
                !_sameDay(previous.createdAt, message.createdAt);
            return Column(
              key: ValueKey('chat-row-${message.id}'),
              children: [
                if (showDay) _DateSeparator(date: message.createdAt),
                _MessageBubble(
                  key: _messageKeys.putIfAbsent(message.id, () => GlobalKey()),
                  message: message,
                  loadAttachment: local?.file != null
                      ? (_) => Future.value(local!.file!)
                      : widget.loadAttachment,
                  conversation: conversation,
                  onSenderTap: senderId == null || senderId.isEmpty
                      ? null
                      : () => _openProfile(senderId),
                  onLongPress:
                      !message.mine &&
                          (message.type == 'IMAGE' ||
                              message.type == 'VOICE' ||
                              message.type == 'TEXT' ||
                              message.type == 'CERAMIC' ||
                              message.type == 'PUBLICATION')
                      ? () => _showMessageActions(message)
                      : null,
                  conversationId: _controller.conversation.id,
                  onCeramicTap:
                      local == null && message.ceramic?.available == true
                      ? () => _openCeramic(message)
                      : null,
                  onPublicationTap: message.publication?.available == true
                      ? () => _openPublication(message)
                      : null,
                ),
                if (local != null) _deliveryStatus(local),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _deliveryStatus(LocalChatSend send) {
    if (send.acknowledged) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .8,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  send.failed
                      ? send.unconfirmed
                            ? context.l10n.requestOutcomeUnconfirmed
                            : context.l10n.chatMessageNotSent
                      : context.l10n.chatMessageSending,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: send.failed ? colors.error : colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (send.failed) ...[
                const SizedBox(height: 6),
                Text(
                  send.unconfirmed
                      ? context.l10n.requestTimedOut
                      : context.l10n.chatMessageSendFailed,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  key: ValueKey('retry-${send.clientId}'),
                  style: TextButton.styleFrom(overlayColor: Colors.transparent),
                  onPressed: !_controller.canRetryLocalSend(send)
                      ? null
                      : () async {
                          await _controller.retryLocalSend(send);
                          if (mounted &&
                              !_controller.localSends.contains(send) &&
                              send.message.type == 'TEXT' &&
                              _composer.text.trim() == send.message.body) {
                            _composer.clear();
                          }
                        },
                  child: Text(context.l10n.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestGuidance() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Text(
          context.l10n.chatRequestGuidance,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.chatRequestMessagesRemaining(
            _controller.conversation.requestMessagesRemaining,
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    ),
  );

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.conversation,
    required this.conversationId,
    this.onCeramicTap,
    this.onPublicationTap,
    this.onLongPress,
    this.onSenderTap,
    this.loadAttachment,
  });
  final ChatMessageDto message;
  final DirectConversationDto conversation;
  final String conversationId;
  final VoidCallback? onLongPress;
  final VoidCallback? onCeramicTap;
  final VoidCallback? onPublicationTap;
  final VoidCallback? onSenderTap;
  final Future<File> Function(ChatMessageDto)? loadAttachment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (message.type == 'SYSTEM') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 20),
        child: Text(
          message.body,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      );
    }
    final isGroup = conversation.type == 'GROUP';
    final isPhoto = message.type == 'IMAGE' && message.attachment != null;
    final isVoice = message.type == 'VOICE' && message.attachment != null;
    final foreground = message.mine ? colors.onPrimary : colors.onSurface;
    final background = message.mine
        ? colors.primary
        : colors.surfaceContainerHighest;
    Widget content;
    if (message.type == 'CERAMIC') {
      content = ChatCeramicCard(
        card: message.ceramic ?? const ChatCeramicCardDto(available: false),
        onTap: onCeramicTap,
        onLongPress: onLongPress,
      );
    } else if (message.type == 'PUBLICATION') {
      content = ChatPublicationCard(
        card:
            message.publication ??
            const ChatPublicationCardDto(available: false),
        onTap: onPublicationTap,
        onLongPress: onLongPress,
      );
    } else {
      content = Semantics(
        button: onLongPress != null,
        hint: onLongPress == null ? null : context.l10n.messageActionsHint,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: message.attachment != null
              ? ChatAttachment(
                  key: ValueKey(message.id),
                  conversation: conversationId,
                  message: message,
                  loadFile: loadAttachment == null
                      ? null
                      : () => loadAttachment!(message),
                )
              : Text(
                  message.body,
                  style: TextStyle(color: foreground, height: 1.25),
                ),
        ),
      );
      // Media owns its own surface; photos have no surrounding bubble.
      if (!isPhoto && !isVoice) {
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: content,
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          mainAxisAlignment: message.mine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.mine) ...[
              Semantics(
                button: onSenderTap != null,
                label: isGroup ? message.senderUsername : conversation.title,
                child: InkWell(
                  key: ValueKey('chat-avatar-${message.id}'),
                  onTap: onSenderTap,
                  customBorder: const CircleBorder(),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                    child: ExcludeSemantics(
                      child: ProfileAvatar(
                        initials: isGroup
                            ? message.senderAvatarInitials ?? '?'
                            : conversation.avatarInitials,
                        colorHex: isGroup
                            ? message.senderAvatarColor ?? '#6D597A'
                            : conversation.avatarColor,
                        imageUrl: isGroup
                            ? message.senderAvatarUrl
                            : conversation.otherUser?.avatarUrl,
                        radius: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * .80,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isGroup &&
                        !message.mine &&
                        message.senderUsername != null)
                      TextButton(
                        key: ValueKey('chat-sender-${message.id}'),
                        onPressed: onSenderTap,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(
                          message.senderUsername!,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    content,
                  ],
                ),
              ),
            ),
          ],
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
