import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/config/router/app_router.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_badge_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
enum NavigationPage {
  home,
  materials,
  discover,
  notifications,
  profile,
}

class NavigationWidget extends StatefulWidget {
  final NavigationPage currentPage;

  const NavigationWidget({
    super.key,
    required this.currentPage,
  });

  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  @override
  void initState() {
    super.initState();
    NavigationBadgeController.instance.refresh();
  }

  void _navigate(
      BuildContext context,
      NavigationPage page,
      ) {
    if (page == widget.currentPage) return;

    switch (page) {
      case NavigationPage.home:
        context.router.replace(
          const HomeRoute(),
          onFailure: (failure) {},
        );
        break;

      case NavigationPage.materials:
        context.router.replace(
          const MaterialsRoute(),
          onFailure: (failure) {},
        );
        break;

      case NavigationPage.discover:
        context.router.replace(
          const ShopRoute(),
          onFailure: (failure) {},
        );
        break;

      case NavigationPage.notifications:
        context.router.replace(
          const NotificationRoute(),
          onFailure: (failure) {},
        );
        break;

      case NavigationPage.profile:
        context.router.replace(
          const ProfileRoute(),
          onFailure: (failure) {},
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,

      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),

      child: SafeArea(
        top: false,

        child: Padding(
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 12,
          ),

          child: Row(
            children: [
              Expanded(
                child: _NavigationItem(
                  label: context.l10n.navigationHome,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,

                  isSelected:
                  widget.currentPage ==
                      NavigationPage.home,

                  onTap: () {
                    _navigate(
                      context,
                      NavigationPage.home,
                    );
                  },
                ),
              ),

              Expanded(
                child: _NavigationItem(
                  label: context.l10n.navigationMaterials,
                  icon:
                  Icons.palette_outlined,

                  selectedIcon:
                  Icons.palette,

                  isSelected:
                  widget.currentPage ==
                      NavigationPage.materials,

                  onTap: () {
                    _navigate(
                      context,
                      NavigationPage.materials,
                    );
                  },
                ),
              ),

              Expanded(
                child: _NavigationItem(
                  label: context.l10n.navigationDiscover,
                  icon: Icons.explore_outlined,

                  selectedIcon:
                  Icons.explore,

                  isSelected:
                  widget.currentPage ==
                      NavigationPage.discover,

                  onTap: () {
                    _navigate(
                      context,
                      NavigationPage.discover,
                    );
                  },
                ),
              ),

              Expanded(
                child: _NavigationItem(
                  label: context.l10n.navigationChats,
                  icon: Icons
                      .notifications_none_outlined,

                  selectedIcon:
                  Icons.notifications,

                  isSelected:
                  widget.currentPage ==
                      NavigationPage
                          .notifications,

                  badgeListenable: NavigationBadgeController.instance.count,

                  onTap: () {
                    _navigate(
                      context,
                      NavigationPage
                          .notifications,
                    );
                  },
                ),
              ),

              Expanded(
                child: _NavigationItem(
                  label: context.l10n.navigationProfile,
                  icon: Icons.person_outline,

                  selectedIcon:
                  Icons.person,

                  isSelected:
                  widget.currentPage ==
                      NavigationPage.profile,

                  onTap: () {
                    _navigate(
                      context,
                      NavigationPage.profile,
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

class _NavigationItem
    extends StatelessWidget {
  final String label;
  final IconData icon;

  final IconData selectedIcon;

  final bool isSelected;

  final ValueListenable<int>? badgeListenable;

  final VoidCallback onTap;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    this.badgeListenable,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTap: onTap,

      child: Container(
        height: double.infinity,

        alignment: Alignment.center,

        child: Stack(
          clipBehavior: Clip.none,

          children: [
            Icon(
              isSelected
                  ? selectedIcon
                  : icon,

              size: 32,
              color: Theme.of(context).colorScheme.onSurface,
            ),

            if (badgeListenable != null)
              ValueListenableBuilder<int>(
                valueListenable: badgeListenable!,
                builder: (context, value, _) => value <= 0
                    ? const SizedBox.shrink()
                    : _Badge(count: value),
              )
          ],
        ),
      ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -6,
      right: -10,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Container(
          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: const BoxDecoration(color: Color(0xFFFF375F), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
