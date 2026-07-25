import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class ArchivedConversationsPage extends StatefulWidget {
  const ArchivedConversationsPage({super.key});

  @override
  State<ArchivedConversationsPage> createState() => _ArchivedConversationsPageState();
}

class _ArchivedConversationsPageState extends State<ArchivedConversationsPage> {
  List<DirectConversationDto> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ChatRepository.getConversations(archived: true);
      if (mounted) setState(() => _items = page.items);
    } catch (exception) {
      if (mounted) setState(() => _error = '$exception');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore(DirectConversationDto item) async {
    try {
      await ChatRepository.restore(item.id);
      await _load();
    } catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$exception')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.archivedChats)),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
              ? Center(
                  child: FilledButton(
                    onPressed: _load,
                    child: Text(context.l10n.retry),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(36),
                          child: Text(
                            context.l10n.noArchivedChats,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ..._items.map(
                        (item) => ListTile(
                          leading: ProfileAvatar(
                            initials: item.avatarInitials,
                            colorHex: item.avatarColor,
                            imageUrl: item.otherUser?.avatarUrl,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            item.lastMessagePreview ?? context.l10n.noMessages,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: context.l10n.restore,
                            onPressed: () => _restore(item),
                            icon: const Icon(Icons.unarchive_outlined),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ConversationPage(initialConversation: item)),
                            );
                            if (mounted) await _load();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
