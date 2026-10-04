import 'package:ceramic_app/ui/widgets/v2/studio_widgets.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
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
      if (mounted) setState(() => _error = context.l10n.operationFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_creating) return;
    final name = _name.text.trim();
    if (name.isEmpty || _selected.isEmpty) return;
    setState(() => _creating = true);
    try {
      final group = await ChatRepository.createGroup(name, _selected.toList());
      if (mounted) Navigator.pop<DirectConversationDto>(context, group);
    } catch (exception) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.operationFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.newGroup),
        actions: [
          TextButton(
            onPressed:
                _creating || _name.text.trim().isEmpty || _selected.isEmpty
                ? null
                : _create,
            child: Text(context.l10n.create),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StudioContent(
          maxWidth: 820,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.list(
                  children: [
                    TextField(
                      controller: _name,
                      maxLength: 100,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: context.l10n.groupName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StudioSectionHeading(
                      title: context.l10n.selectFriendsMemberCount(
                        _selected.length + 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: StudioEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: context.l10n.operationFailed,
                    action: FilledButton(
                      onPressed: _loadFriends,
                      child: Text(context.l10n.retry),
                    ),
                  ),
                )
              else if (_friends.isEmpty)
                SliverToBoxAdapter(
                  child: StudioEmptyState(
                    icon: Icons.people_outline,
                    title: context.l10n.addFriendBeforeGroup,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.builder(
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
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
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
