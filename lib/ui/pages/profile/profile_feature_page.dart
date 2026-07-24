import 'package:ceramic_app/ui/pages/profile/friends_page.dart';
import 'package:ceramic_app/ui/pages/profile/profile_edit_page.dart';
import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/pages/profile/user_search_page.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_view/ceramic_view_page.dart';
import 'package:ceramic_app/ui/widgets/ceramic_journal_card.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class ProfileFeaturePage extends StatefulWidget {
  const ProfileFeaturePage({super.key});

  @override
  State<ProfileFeaturePage> createState() => _ProfileFeaturePageState();
}

class _ProfileFeaturePageState extends State<ProfileFeaturePage> {
  final ProfilePageController _controller = ProfilePageController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Search accounts',
            onPressed: () => _open(const UserSearchPage()),
            icon: const Icon(Icons.search, color: Colors.black),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.account == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.error != null && _controller.account == null) {
              return _Retry(message: _controller.error!, onRetry: _controller.load);
            }
            final account = _controller.account;
            if (account == null) return const SizedBox.shrink();
            return RefreshIndicator(
              onRefresh: _controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 18),
                  Center(
                    child: ProfileAvatar(
                      initials: account.avatarInitials,
                      colorHex: account.avatarColor,
                      imageUrl: account.avatarUrl,
                      radius: 42,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    account.username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 9),
                  Center(
                    child: SizedBox(
                      height: 34,
                      child: FilledButton(
                        onPressed: () => _open(ProfileEditPage(controller: _controller)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xffeeeeee),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                        ),
                        child: const Text('Edit profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _open(FriendsPage(controller: _controller)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              _controller.friendsCursor == null
                                  ? '${_controller.friends.length}'
                                  : '${_controller.friends.length}+',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            const Text('Friends', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                    child: Row(children: [
                      Text('Finished pieces', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('${_controller.finishedCeramics.length}'),
                    ]),
                  ),
                  if (_controller.finishedCeramics.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 28, 24, 70),
                      child: Column(children: [
                        Icon(Icons.auto_awesome_outlined, size: 40, color: Colors.black38),
                        SizedBox(height: 10),
                        Text(
                          'Pieces moved to Finished will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ]),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _controller.finishedCeramics.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .72,
                        ),
                        itemBuilder: (_, index) {
                          final ceramic = _controller.finishedCeramics[index];
                          final stage = _controller.stages
                              .where((item) => item.id == ceramic.stageId)
                              .first;
                          final clay = _controller.clays
                              .where((item) => item.id == ceramic.clayTypeId)
                              .map((item) => item.title)
                              .firstOrNull;
                          return CeramicJournalCard(
                            ceramic: ceramic,
                            stageTitle: stage.title,
                            clayTitle: clay,
                            onTap: () => _open(CeramicViewPage(
                              ceramic: ceramic,
                              stages: _controller.stages,
                              clayTypes: _controller.clays,
                              glazes: _controller.glazes,
                            )),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const NavigationWidget(currentPage: NavigationPage.profile),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
