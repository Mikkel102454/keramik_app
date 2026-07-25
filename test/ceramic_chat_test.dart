import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/shared_ceramic_dto.dart';
import 'package:ceramic_app/ui/pages/notification/shared_ceramic_detail_page.dart';
import 'package:ceramic_app/ui/widgets/chat_ceramic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('ceramic chat card preserves live and unavailable layouts', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatCeramicCard(
                card: const ChatCeramicCardDto(
                  available: true,
                  title: 'Shared bowl',
                  stage: 'Glazed',
                  clayTitle: 'Stoneware',
                  rating: 4,
                ),
                onTap: () {},
              ),
              const ChatCeramicCard(
                card: ChatCeramicCardDto(available: false),
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Shared bowl'), findsOneWidget);
    expect(find.text('Stoneware'), findsOneWidget);
    expect(find.text('Glazed'), findsOneWidget);
    expect(find.text('This ceramic is no longer available.'), findsOneWidget);
  });

  testWidgets('shared ceramic detail is complete and has no mutation controls', (
    tester,
  ) async {
    final detail = SharedCeramicDetailDto(
      available: true,
      title: 'Read-only vase',
      stage: 'Finished',
      clayTitle: 'Porcelain',
      rating: 5,
      weight: 720,
      heightCm: 18,
      note: 'Private project notes now shared',
      outcomeNote: 'Kept',
      tags: const ['gift'],
      glazes: const [
        SharedCeramicGlazeDto(
          title: 'Celadon',
          note: 'Two even coats',
          layerOrder: 1,
          coatCount: 2,
        ),
      ],
      firings: const [],
      stageHistory: const [],
      images: const [],
      imageCount: 0,
      createdAt: DateTime(2026, 7, 20),
      updatedAt: DateTime(2026, 7, 25),
    );
    await tester.pumpWidget(
      localizedTestApp(
        home: SharedCeramicDetailPage(
          conversationId: 'conversation',
          messageId: 'message',
          loadDetail: (_, _) async => detail,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read-only vase'), findsOneWidget);
    expect(find.text('Private project notes now shared'), findsOneWidget);
    expect(find.text('Celadon'), findsOneWidget);
    expect(find.text('720.0 kg'), findsOneWidget);
    final history = tester.widget<ExpansionTile>(
      find.widgetWithText(ExpansionTile, 'History'),
    );
    expect(history.initiallyExpanded, isFalse);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.share), findsNothing);
  });

  testWidgets('shared ceramic weight follows the active imperial setting', (
    tester,
  ) async {
    await AppSettingsController.instance.applyLocalSettings(
      const AccountSettingsDto(
        measurementSystem: MeasurementSystem.imperial,
      ),
    );
    addTearDown(
      () => AppSettingsController.instance.applyLocalSettings(
        const AccountSettingsDto(),
      ),
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: SharedCeramicDetailPage(
          conversationId: 'conversation',
          messageId: 'message',
          loadDetail: (_, _) async => SharedCeramicDetailDto(
            available: true,
            title: 'Imperial vase',
            weight: 10,
            tags: const [],
            glazes: const [],
            firings: const [],
            stageHistory: const [],
            images: const [],
            imageCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('22 lb'), findsOneWidget);
  });
}
