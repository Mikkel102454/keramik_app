import 'package:ceramic_app/objects/chat_dto.dart';
import 'package:ceramic_app/objects/chat_report_dto.dart';
import 'package:ceramic_app/ui/pages/notification/report_message_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';

void main() {
  test('parses report receipt and validates Unicode explanation length', () {
    final receipt = ChatReportReceiptDto.fromJson({
      'reportId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'createdAt': '2026-07-22T17:30:00Z',
    });

    expect(receipt.reportId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    expect(validateChatReport(null, ''), isNotNull);
    expect(validateChatReport(ChatReportCategory.other, '  '), isNotNull);
    final thousandEmoji = List.filled(1000, '😀').join();
    expect(validateChatReport(ChatReportCategory.spam, thousandEmoji), isNull);
    expect(
      validateChatReport(ChatReportCategory.spam, '$thousandEmoji😀'),
      isNotNull,
    );
  });

  testWidgets(
    'report form discloses context and submits the approved contract',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ChatReportCategory? submittedCategory;
      String? submittedExplanation;
      String? submittedConversation;
      String? submittedMessage;
      final message = ChatMessageDto(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        senderUserId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        body: 'Message selected for reporting',
        createdAt: DateTime.utc(2026, 7, 22, 17, 30),
        sequence: 5,
        mine: false,
      );

      await tester.pumpWidget(
        localizedTestApp(
          home: ReportMessagePage(
            conversationId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
            message: message,
            submitReport:
                ({
                  required conversationId,
                  required messageId,
                  required category,
                  explanation,
                }) async {
                  submittedConversation = conversationId;
                  submittedMessage = messageId;
                  submittedCategory = category;
                  submittedExplanation = explanation;
                  return ChatReportReceiptDto(
                    reportId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
                    createdAt: DateTime.utc(2026, 7, 22, 17, 31),
                  );
                },
          ),
        ),
      );

      expect(find.textContaining('up to two nearby messages'), findsOneWidget);
      expect(find.textContaining('does not block'), findsOneWidget);
      final submitButton = find.text('Submit report');
      await tester.tap(submitButton);
      await tester.pump();
      expect(find.text('Choose a reason for this report.'), findsOneWidget);

      await tester.tap(find.text('Other'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();
      expect(
        find.text('Add an explanation when choosing Other.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '  Useful context  ');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(submittedConversation, 'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
      expect(submittedMessage, message.id);
      expect(submittedCategory, ChatReportCategory.other);
      expect(submittedExplanation, 'Useful context');
    },
  );
}
