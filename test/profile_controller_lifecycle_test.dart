import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/pages/profile/user_search_controller.dart';
import 'package:ceramic_app/ui/pages/notification/notification_controller_page.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile controller ignores refresh after disposal', () async {
    final controller = ProfilePageController();
    controller.dispose();

    await expectLater(controller.load(), completes);
    await expectLater(controller.loadMoreFriends(), completes);
  });

  test('profile exposes only ceramics in the finished stage', () {
    final controller = ProfilePageController();
    controller.stages = [
      StageDto(id: 1, title: 'Ideas'),
      StageDto(id: 6, title: 'Finished'),
    ];
    controller.ceramics = [
      _ceramic(1, 1),
      _ceramic(2, 6),
    ];

    expect(controller.finishedCeramics.map((item) => item.id), [2]);
    controller.dispose();
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

CeramicDto _ceramic(int id, int stageId) => CeramicDto(
  id: id,
  stageId: stageId,
  title: 'Piece $id',
  clayTypeId: 0,
  rating: 0,
  weight: 0,
  note: '',
  glazes: const [],
  tags: const [],
  images: const [],
);
