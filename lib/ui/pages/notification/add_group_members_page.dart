import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class AddGroupMembersPage extends StatefulWidget {
  const AddGroupMembersPage({required this.group, super.key});
  final DirectConversationDto group;

  @override
  State<AddGroupMembersPage> createState() => _AddGroupMembersPageState();
}

class _AddGroupMembersPageState extends State<AddGroupMembersPage> {
  final Set<String> _selected = {};
  List<UserProfileDto> _friends = const [];
  bool _loading = true;
  bool _adding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  Future<void> _add() async {
    if (_selected.isEmpty) return;
    setState(() => _adding = true);
    try {
      await ChatRepository.addGroupMembers(widget.group.id, _selected.toList());
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) {
        setState(() => _adding = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$exception')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 50 - widget.group.memberCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.addMembers),
        actions: [
          TextButton(
            onPressed: _adding || _selected.isEmpty ? null : _add,
            child: Text(context.l10n.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: FilledButton(
                    onPressed: _load,
                    child: Text(context.l10n.retry),
                  ),
                )
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(context.l10n.chooseFriendsLimit(remaining)),
                    ),
                    ..._friends.map((friend) {
                      final selected = _selected.contains(friend.userId);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: _selected.length >= remaining && !selected
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
                    }),
                  ],
                ),
    );
  }
}
