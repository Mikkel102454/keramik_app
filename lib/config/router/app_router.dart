import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/ui/pages/home/home_page.dart';
import 'package:ceramic_app/ui/pages/v2/pages.dart';
import 'package:injectable/injectable.dart';

import 'package:ceramic_app/ui/pages/login/login_page.dart';
import 'package:ceramic_app/ui/pages/test_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
@Singleton()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: LoginRoute.page,
      initial: true,
    ),
    AutoRoute(
      page: HomeRoute.page,
    ),
    AutoRoute(
      page: ProfileRoute.page,
    ),
    AutoRoute(
      page: ShopRoute.page,
    ),
    AutoRoute(
      page: NotificationsRoute.page,
    ),
    AutoRoute(
      page: TestRoute.page,
    ),
  ];
}