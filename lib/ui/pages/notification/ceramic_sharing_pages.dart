import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';
import 'package:clay_dock/ui/widgets/feature_gate.dart';
import 'package:clay_dock/objects/entitlement_dto.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/objects/ceramic_dto.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/objects/clay_dto.dart';
import 'package:clay_dock/objects/stage_dto.dart';
import 'package:clay_dock/objects/user_profile_dto.dart';
import 'package:clay_dock/repositories/ceramic_repository.dart';
import 'package:clay_dock/repositories/chat_repository.dart';
import 'package:clay_dock/repositories/clay_repository.dart';
import 'package:clay_dock/repositories/stage_repository.dart';
import 'package:clay_dock/ui/widgets/ceramic_journal_card.dart';
import 'package:clay_dock/ui/widgets/profile_avatar.dart';
import 'package:clay_dock/utils/client_uuid.dart';
import 'package:flutter/material.dart';

Future<bool> confirmCeramicShare(
  BuildContext context, {
  bool checkMembership = true,
  bool publicPublication = false,
}) async {
  if (checkMembership &&
      !publicPublication &&
      (!await requireFeature(context, Features.privateCeramicSharing) ||
          !context.mounted)) {
    return false;
  }
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.shareCeramic),
          content: Text(
            publicPublication
                ? context.l10n.publicationChatShareDisclosure
                : context.l10n.shareCeramicDisclosure,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.share),
            ),
          ],
        ),
      ) ??
      false;
}

typedef ConversationPageLoader =
    Future<CursorPage<DirectConversationDto>> Function({String? cursor});
typedef PublicationConversationSender =
    Future<void> Function(
      String conversationId,
      String clientMessageId,
      String publicationId,
    );
typedef CeramicConversationSender =
    Future<void> Function(
      String conversationId,
      String clientMessageId,
      int ceramicId,
    );
typedef ShareConfirmation = Future<bool> Function(BuildContext context);

class CeramicPickerPage extends StatefulWidget {
  const CeramicPickerPage({super.key});

  @override
  State<CeramicPickerPage> createState() => _CeramicPickerPageState();
}

class _CeramicPickerPageState extends State<CeramicPickerPage> {
  late Future<_CeramicPickerData> _load = _fetch();

  Future<_CeramicPickerData> _fetch() async {
    final results = await Future.wait<dynamic>([
      CeramicRepository.getCeramics(),
      StageRepository.getStages(),
      ClayRepository.getClayTypes(),
    ]);
    return _CeramicPickerData(
      results[0] as List<CeramicDto>,
      results[1] as List<StageDto>,
      results[2] as List<ClayDto>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chooseCeramic)),
      body: SafeArea(
        top: false,
        child: StudioContent(
          maxWidth: 820,
          child: FutureBuilder<_CeramicPickerData>(
            future: _load,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: FilledButton(
                    onPressed: () => setState(() => _load = _fetch()),
                    child: Text(context.l10n.retry),
                  ),
                );
              }
              final data = snapshot.requireData;
              if (data.ceramics.isEmpty) {
                return StudioEmptyState(
                  icon: Icons.ios_share_outlined,
                  title: context.l10n.noCeramicsToShare,
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        (constraints.maxWidth /
                                (230 *
                                    (MediaQuery.textScalerOf(
                                              context,
                                            ).scale(14) /
                                            14)
                                        .clamp(1, 1.5)))
                            .floor()
                            .clamp(1, 4)
                            .toInt(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent:
                        350.0 +
                        (MediaQuery.textScalerOf(context).scale(14) / 14 - 1)
                                .clamp(0, 2)
                                .toDouble() *
                            100,
                  ),
                  itemCount: data.ceramics.length,
                  itemBuilder: (context, index) {
                    final ceramic = data.ceramics[index];
                    String? stage;
                    String? clay;
                    for (final item in data.stages) {
                      if (item.id == ceramic.stageId) stage = item.title;
                    }
                    for (final item in data.clays) {
                      if (item.id == ceramic.clayTypeId) clay = item.title;
                    }
                    return CeramicJournalCard(
                      ceramic: ceramic,
                      stageTitle: localizedStageName(context.l10n, stage ?? ''),
                      clayTitle: clay,
                      onTap: () => Navigator.pop(context, ceramic),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ShareCeramicConversationPickerPage extends StatefulWidget {
  const ShareCeramicConversationPickerPage({
    required this.ceramicId,
    this.loadConversations,
    this.sendPublication,
    this.sendCeramic,
    this.confirmShare,
    super.key,
  }) : publicationId = null;

  const ShareCeramicConversationPickerPage.publication({
    required this.publicationId,
    this.loadConversations,
    this.sendPublication,
    this.sendCeramic,
    this.confirmShare,
    super.key,
  }) : ceramicId = null;

  final int? ceramicId;
  final String? publicationId;
  final ConversationPageLoader? loadConversations;
  final PublicationConversationSender? sendPublication;
  final CeramicConversationSender? sendCeramic;
  final ShareConfirmation? confirmShare;

  @override
  State<ShareCeramicConversationPickerPage> createState() =>
      _ShareCeramicConversationPickerPageState();
}

class _ShareCeramicConversationPickerPageState
    extends State<ShareCeramicConversationPickerPage> {
  final List<DirectConversationDto> _items = [];
  final Map<String, String> _clientIds = {};
  String? _cursor;
  String? _error;
  bool _loading = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loader =
          widget.loadConversations ?? ChatRepository.getConversations;
      final page = await loader(cursor: _cursor);
      final writable = page.items.where(
        (item) => !item.archived && !item.readOnly && item.status == 'ACTIVE',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items.addAll(
          writable.where(
            (item) => _items.every((existing) => existing.id != item.id),
          ),
        );
        _cursor = page.nextCursor;
      });
    } catch (exception) {
      if (mounted) setState(() => _error = context.l10n.operationFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share(DirectConversationDto conversation) async {
    final confirmation =
        widget.confirmShare ??
        (BuildContext context) => confirmCeramicShare(
          context,
          checkMembership: !_clientIds.containsKey(conversation.id),
          publicPublication: widget.publicationId != null,
        );
    if (_sending || !await confirmation(context)) {
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final clientId = _clientIds.putIfAbsent(
        conversation.id,
        createClientUuid,
      );
      if (widget.publicationId case final publicationId?) {
        final sender = widget.sendPublication ?? ChatRepository.sendPublication;
        await sender(conversation.id, clientId, publicationId);
      } else {
        final sender = widget.sendCeramic ?? ChatRepository.sendCeramic;
        await sender(conversation.id, clientId, widget.ceramicId!);
      }
      _clientIds.remove(conversation.id);
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) setState(() => _error = context.l10n.operationFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.shareToConversation)),
      body: SafeArea(
        top: false,
        child: StudioContent(
          maxWidth: 820,
          child: SafeArea(
            child: Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty && _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                      ? Center(
                          child: Text(context.l10n.noWritableConversations),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              enabled: !_sending,
                              leading: ProfileAvatar(
                                initials: item.avatarInitials,
                                colorHex: item.avatarColor,
                                imageUrl: item.otherUser?.avatarUrl,
                              ),
                              title: Text(item.title),
                              subtitle: Text(
                                item.type == 'GROUP'
                                    ? context.l10n.memberCount(item.memberCount)
                                    : context.l10n.directConversation,
                              ),
                              onTap: () => _share(item),
                            );
                          },
                        ),
                ),
                if (_cursor != null)
                  TextButton(
                    onPressed: _loading ? null : _load,
                    child: Text(
                      _loading ? context.l10n.loading : context.l10n.loadMore,
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

class _CeramicPickerData {
  const _CeramicPickerData(this.ceramics, this.stages, this.clays);

  final List<CeramicDto> ceramics;
  final List<StageDto> stages;
  final List<ClayDto> clays;
}
