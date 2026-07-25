import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/account_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

typedef BlockedAccountsLoader = Future<CursorPage<UserProfileDto>> Function({
  String? cursor,
});
typedef AccountUnblocker = Future<void> Function(String userId);

class BlockedAccountsPage extends StatefulWidget {
  final BlockedAccountsLoader? loader;
  final AccountUnblocker? unblocker;

  const BlockedAccountsPage({super.key, this.loader, this.unblocker});

  @override
  State<BlockedAccountsPage> createState() => _BlockedAccountsPageState();
}

class _BlockedAccountsPageState extends State<BlockedAccountsPage> {
  final List<UserProfileDto> _accounts = [];
  String? _cursor;
  String? _error;
  bool _loading = false;
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await (widget.loader ?? AccountRepository.getBlocks)(
        cursor: reset ? null : _cursor,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _accounts.clear();
        _accounts.addAll(page.items);
        _cursor = page.nextCursor;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.blockedAccountsLoadFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(UserProfileDto account) async {
    final index = _accounts.indexOf(account);
    setState(() {
      _accounts.remove(account);
      _removing.add(account.userId);
      _error = null;
    });
    try {
      await (widget.unblocker ?? SocialRepository.unblock)(account.userId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final restoredIndex = index < 0
            ? 0
            : index > _accounts.length
            ? _accounts.length
            : index;
        _accounts.insert(restoredIndex, account);
        _error = context.l10n.accountUnblockFailed(account.username);
      });
    } finally {
      if (mounted) setState(() => _removing.remove(account.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.blockedAccounts)),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_error != null)
              MaterialBanner(
                content: Text(_error!),
                actions: [
                  TextButton(
                    onPressed: () => _load(reset: _accounts.isEmpty),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            if (_loading && _accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 100, 28, 0),
                child: Column(
                  children: [
                    const Icon(Icons.block_outlined, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noBlockedAccounts,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._accounts.map(
                (account) => ListTile(
                  leading: ProfileAvatar(
                    initials: account.avatarInitials,
                    colorHex: account.avatarColor,
                    imageUrl: account.avatarUrl,
                    radius: 23,
                  ),
                  title: Text(account.username),
                  trailing: OutlinedButton(
                    onPressed: _removing.contains(account.userId)
                        ? null
                        : () => _unblock(account),
                    child: Text(context.l10n.unblock),
                  ),
                ),
              ),
            if (_cursor != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: OutlinedButton(
                  onPressed: _loading ? null : _load,
                  child: Text(
                    _loading ? context.l10n.loading : context.l10n.loadMore,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
