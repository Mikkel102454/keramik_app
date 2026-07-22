import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/pages/profile/user_search_controller.dart';
import 'package:ceramic_app/ui/pages/notification/notification_controller_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile controller ignores refresh after disposal', () async {
    final controller = ProfilePageController();
    controller.dispose();

    await expectLater(controller.load(), completes);
    await expectLater(controller.loadMoreFriends(), completes);
  });

  test('search controller ignores work after disposal', () async {
    final controller = UserSearchController();
    controller.dispose();

    expect(() => controller.queryChanged('alice'), returnsNormally);
    await expectLater(controller.retry(), completes);
    await expectLater(controller.loadMore(), completes);
  });

  test('inbox controller ignores refresh after disposal', () async {
    final controller = NotificationControllerPage();
    controller.dispose();

    await expectLater(controller.load(), completes);
  });
}
