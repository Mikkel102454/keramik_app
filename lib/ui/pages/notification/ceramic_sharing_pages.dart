import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:ceramic_app/repositories/stage_repository.dart';
import 'package:ceramic_app/ui/widgets/ceramic_journal_card.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:ceramic_app/utils/client_uuid.dart';
import 'package:flutter/material.dart';

Future<bool> confirmCeramicShare(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.shareCeramic),
          content: Text(context.l10n.shareCeramicDisclosure),
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
      body: FutureBuilder<_CeramicPickerData>(
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
            return Center(child: Text(context.l10n.noCeramicsToShare));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .72,
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
          );
        },
      ),
    );
  }
}

class ShareCeramicConversationPickerPage extends StatefulWidget {
  const ShareCeramicConversationPickerPage({
    required this.ceramicId,
    super.key,
  }) : publicationId = null;

  const ShareCeramicConversationPickerPage.publication({
    required this.publicationId,
    super.key,
  }) : ceramicId = null;

  final int? ceramicId;
  final String? publicationId;

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
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ChatRepository.getConversations(cursor: _cursor);
      final writable = page.items.where(
        (item) => !item.archived && !item.readOnly && item.status == 'ACTIVE',
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(writable.where(
          (item) => _items.every((existing) => existing.id != item.id),
        ));
        _cursor = page.nextCursor;
      });
    } catch (exception) {
      if (mounted) setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share(DirectConversationDto conversation) async {
    if (_sending || !await confirmCeramicShare(context)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final clientId = _clientIds.putIfAbsent(conversation.id, createClientUuid);
      if (widget.publicationId case final publicationId?) {
        await ChatRepository.sendPublication(
          conversation.id,
          clientId,
          publicationId,
        );
      } else {
        await ChatRepository.sendCeramic(
          conversation.id,
          clientId,
          widget.ceramicId!,
        );
      }
      _clientIds.remove(conversation.id);
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.shareToConversation)),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: _items.isEmpty && _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? Center(child: Text(context.l10n.noWritableConversations))
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
                child: Text(_loading ? context.l10n.loading : context.l10n.loadMore),
              ),
          ],
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
