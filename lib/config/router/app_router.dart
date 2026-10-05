import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:clay_dock/ui/pages/notification/notification_controller_page.dart';
import 'package:clay_dock/ui/pages/discover/discover_controller.dart';
import 'package:clay_dock/ui/pages/home/home_page.dart';
import 'package:clay_dock/ui/pages/notification/notification_page.dart';
import 'package:clay_dock/ui/pages/materials/materials_page.dart';
import 'package:clay_dock/ui/pages/v2/pages.dart';

import 'package:clay_dock/ui/pages/login/login_page.dart';
import 'package:clay_dock/ui/pages/test_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.custom(
    duration: Duration.zero,
    reverseDuration: Duration.zero,
    transitionsBuilder: TransitionsBuilders.noTransition,
  );

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, initial: true),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: ProfileRoute.page),
    AutoRoute(page: ShopRoute.page),
    AutoRoute(page: NotificationRoute.page),
    AutoRoute(page: MaterialsRoute.page),
  ];
}
