import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class NewGroupPage extends StatefulWidget {
  const NewGroupPage({super.key});

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final TextEditingController _name = TextEditingController();
  final Set<String> _selected = {};
  List<UserProfileDto> _friends = const [];
  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final users = <UserProfileDto>[];
      String? cursor;
      do {
        final page = await SocialRepository.getFriends(cursor: cursor);
        users.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null);
      if (mounted) setState(() => _friends = users);
    } catch (exception) {
      if (mounted) setState(() => _error = '$exception');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty || _selected.isEmpty) return;
    setState(() => _creating = true);
    try {
      final group = await ChatRepository.createGroup(name, _selected.toList());
      if (mounted) Navigator.pop<DirectConversationDto>(context, group);
    } catch (exception) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$exception')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New group'),
        actions: [
          TextButton(
            onPressed: _creating || _name.text.trim().isEmpty || _selected.isEmpty ? null : _create,
            child: const Text('Create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _name,
              maxLength: 100,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Group name', border: OutlineInputBorder()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select friends · ${_selected.length + 1}/50 members',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: FilledButton(onPressed: _loadFriends, child: const Text('Retry')))
                    : _friends.isEmpty
                        ? const Center(child: Text('Add a friend before creating a group.'))
                        : ListView(
                            children: _friends.map((friend) {
                              final selected = _selected.contains(friend.userId);
                              return CheckboxListTile(
                                value: selected,
                                onChanged: _selected.length >= 49 && !selected
                                    ? null
                                    : (value) => setState(() {
                                          if (value == true) {
                                            _selected.add(friend.userId);
                                          } else {
                                            _selected.remove(friend.userId);
                                          }
                                        }),
                                secondary: ProfileAvatar(
                                  initials: friend.avatarInitials,
                                  colorHex: friend.avatarColor,
                                  imageUrl: friend.avatarUrl,
                                ),
                                title: Text(friend.username),
                              );
                            }).toList(),
                          ),
          ),
        ],
      ),
    );
  }
}
