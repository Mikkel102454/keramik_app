// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [MaterialsPage]
class MaterialsRoute extends PageRouteInfo<void> {
  const MaterialsRoute({List<PageRouteInfo>? children})
    : super(MaterialsRoute.name, initialChildren: children);

  static const String name = 'MaterialsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MaterialsPage();
    },
  );
}

/// generated route for
/// [NotificationPage]
class NotificationRoute extends PageRouteInfo<NotificationRouteArgs> {
  NotificationRoute({
    Key? key,
    NotificationControllerPage? controller,
    List<PageRouteInfo>? children,
  }) : super(
         NotificationRoute.name,
         args: NotificationRouteArgs(key: key, controller: controller),
         initialChildren: children,
       );

  static const String name = 'NotificationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NotificationRouteArgs>(
        orElse: () => const NotificationRouteArgs(),
      );
      return NotificationPage(key: args.key, controller: args.controller);
    },
  );
}

class NotificationRouteArgs {
  const NotificationRouteArgs({this.key, this.controller});

  final Key? key;

  final NotificationControllerPage? controller;

  @override
  String toString() {
    return 'NotificationRouteArgs{key: $key, controller: $controller}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotificationRouteArgs) return false;
    return key == other.key && controller == other.controller;
  }

  @override
  int get hashCode => key.hashCode ^ controller.hashCode;
}

/// generated route for
/// [NotificationsPage]
class NotificationsRoute extends PageRouteInfo<void> {
  const NotificationsRoute({List<PageRouteInfo>? children})
    : super(NotificationsRoute.name, initialChildren: children);

  static const String name = 'NotificationsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NotificationsPage();
    },
  );
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [ShopPage]
class ShopRoute extends PageRouteInfo<ShopRouteArgs> {
  ShopRoute({
    DiscoverController? forYouController,
    DiscoverController? latestController,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ShopRoute.name,
         args: ShopRouteArgs(
           forYouController: forYouController,
           latestController: latestController,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'ShopRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ShopRouteArgs>(
        orElse: () => const ShopRouteArgs(),
      );
      return ShopPage(
        forYouController: args.forYouController,
        latestController: args.latestController,
        key: args.key,
      );
    },
  );
}

class ShopRouteArgs {
  const ShopRouteArgs({this.forYouController, this.latestController, this.key});

  final DiscoverController? forYouController;

  final DiscoverController? latestController;

  final Key? key;

  @override
  String toString() {
    return 'ShopRouteArgs{forYouController: $forYouController, latestController: $latestController, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShopRouteArgs) return false;
    return forYouController == other.forYouController &&
        latestController == other.latestController &&
        key == other.key;
  }

  @override
  int get hashCode =>
      forYouController.hashCode ^ latestController.hashCode ^ key.hashCode;
}

/// generated route for
/// [TestPage]
class TestRoute extends PageRouteInfo<void> {
  const TestRoute({List<PageRouteInfo>? children})
    : super(TestRoute.name, initialChildren: children);

  static const String name = 'TestRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TestPage();
    },
  );
}
