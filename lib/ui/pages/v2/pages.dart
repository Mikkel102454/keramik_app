import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:flutter/material.dart';

@RoutePage()
class GlazesPage extends StatelessWidget {
  const GlazesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar:
        const NavigationWidget(
          currentPage:
          NavigationPage.glazes,
        ),
      ),
    );
  }
}

@RoutePage()
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar:
        const NavigationWidget(
          currentPage:
          NavigationPage.shop,
        ),
      ),
    );
  }
}

@RoutePage()
class NotificationsPage
    extends StatelessWidget {
  const NotificationsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar:
        const NavigationWidget(
          currentPage:
          NavigationPage
              .notifications,
        ),
      ),
    );
  }
}

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar:
        const NavigationWidget(
          currentPage:
          NavigationPage.profile,
        ),
      ),
    );
  }
}