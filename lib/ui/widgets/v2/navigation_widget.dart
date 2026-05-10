import 'package:ceramic_app/ui/pages/home/home_page.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/ui/pages/v2/pages.dart';
import 'package:ceramic_app/ui/pages/test_page.dart';

enum NavigationPage {
  home,
  glazes,
  shop,
  notifications,
  profile,
}

class NavigationWidget extends StatelessWidget {
  final NavigationPage currentPage;

  const NavigationWidget({
    super.key,
    required this.currentPage,
  });

  void _navigate(
      BuildContext context,
      NavigationPage page,
      ) {
    if (page == currentPage) {
      return;
    }

    Widget targetPage;

    switch (page) {
      case NavigationPage.home:
        targetPage = const HomePage();
        break;

      case NavigationPage.glazes:
        targetPage = const GlazesPage();
        break;

      case NavigationPage.shop:
        targetPage = const ShopPage();
        break;

      case NavigationPage.notifications:
        targetPage =
        const NotificationsPage();
        break;

      case NavigationPage.profile:
        targetPage = const TestPage();
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (
            context,
            animation,
            secondaryAnimation,
            ) {
          return targetPage;
        },

        transitionDuration: Duration.zero,
        reverseTransitionDuration:
        Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,

      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
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
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,

                  isSelected:
                  currentPage ==
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
                  icon:
                  Icons.palette_outlined,

                  selectedIcon:
                  Icons.palette,

                  isSelected:
                  currentPage ==
                      NavigationPage.glazes,

                  onTap: () {
                    _navigate(
                      context,
                      NavigationPage.glazes,
                    );
                  },
                ),
              ),

              Expanded(
                child: _NavigationItem(
                  icon: Icons
                      .shopping_cart_outlined,

                  selectedIcon:
                  Icons.shopping_cart,

                  isSelected:
                  currentPage ==
                      NavigationPage.shop,

                  onTap: () {
                    _navigate(
                      context,
                      NavigationPage.shop,
                    );
                  },
                ),
              ),

              Expanded(
                child: _NavigationItem(
                  icon: Icons
                      .notifications_none_outlined,

                  selectedIcon:
                  Icons.notifications,

                  isSelected:
                  currentPage ==
                      NavigationPage
                          .notifications,

                  badgeCount: 4,

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
                  icon: Icons.person_outline,

                  selectedIcon:
                  Icons.person,

                  isSelected:
                  currentPage ==
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
  final IconData icon;

  final IconData selectedIcon;

  final bool isSelected;

  final int? badgeCount;

  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              color: Colors.black,
            ),

            if (badgeCount != null &&
                badgeCount! > 0)
              Positioned(
                top: -6,
                right: -10,

                child: Container(
                  padding: const EdgeInsets.all(2),

                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),

                  child: Container(
                    width: 22,
                    height: 22,

                    decoration: const BoxDecoration(
                      color: Color(0xFFFF375F),
                      shape: BoxShape.circle,
                    ),

                    child: Center(
                      child: Text(
                        badgeCount.toString(),

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}