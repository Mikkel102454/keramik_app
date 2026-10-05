import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/repositories/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_dock/utils/emoji_insertion.dart';
import 'package:clay_dock/objects/ceramic_dto.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/ui/pages/home/ceramic_journal_query.dart';
import 'package:clay_dock/ui/pages/settings/push_device_controls.dart';
import 'test_app.dart';

CeramicDto piece(int id, {DateTime? viewed}) => CeramicDto(
  id: id,
  stageId: 1,
  title: 'bowl $id',
  clayTypeId: 0,
  rating: 3,
  weight: 0,
  note: '',
  glazes: [],
  tags: [],
  images: [],
  lastViewedAt: viewed,
);
void main() {
  test(
    'attachment failures and cancellation remove partially downloaded private files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chat-download-test-',
      );
      ApiClient.dio = Dio(
        BaseOptions(baseUrl: 'http://localhost', validateStatus: (_) => true),
      );
      ApiClient.dio.httpClientAdapter = _DeniedDownload();
      final target = File('${directory.path}/attachment.jpg');
      try {
        await expectLater(
          ChatRepository.downloadAttachment(
            'conversation',
            'message',
            target,
            CancelToken(),
          ),
          throwsA(isA<FileSystemException>()),
        );
        expect(await target.exists(), isFalse);
        await target.writeAsString('partial private file');
        final token = CancelToken()..cancel();
        await expectLater(
          ChatRepository.downloadAttachment(
            'conversation',
            'message',
            target,
            token,
          ),
          throwsA(isA<DioException>()),
        );
        expect(await target.exists(), isFalse);
      } finally {
        ApiClient.dio.close(force: true);
        await directory.delete(recursive: true);
      }
    },
  );
  test(
    'recently viewed is newest first with deterministic ties and nulls last with filters',
    () {
      final at = DateTime.utc(2026, 10, 3);
      final pieces = [
        piece(4),
        piece(3, viewed: at),
        piece(2, viewed: at.subtract(const Duration(days: 1))),
        piece(1, viewed: at),
      ];
      const query = CeramicJournalQuery(
        sort: CeramicJournalSort.recentlyViewed,
        stageIds: {1},
        search: 'bowl',
        minimumRating: 3,
      );
      expect(query.apply(pieces, [], []).map((c) => c.id), [1, 3, 2, 4]);
      expect(
        query
            .copyWith(descending: false)
            .apply(pieces, [], [])
            .map((c) => c.id),
        [1, 3, 2, 4],
      );
      expect(query.copyWith(stageIds: {2}).apply(pieces, [], []), isEmpty);
    },
  );
  test(
    'view metadata is additive and older ceramic payloads remain readable',
    () {
      final original = piece(1);
      final json = original.toJson();
      json.remove('lastViewedAt');
      expect(CeramicDto.fromJson(json).lastViewedAt, isNull);
      original.lastViewedAt = DateTime.utc(2026, 10, 3);
      expect(
        CeramicDto.fromJson(original.toJson()).lastViewedAt,
        original.lastViewedAt,
      );
    },
  );
  test(
    'emoji replaces selection and preserves family and skin tone sequences',
    () {
      const value = TextEditingValue(
        text: 'abXYZcd',
        selection: TextSelection(baseOffset: 2, extentOffset: 5),
      );
      const emoji = '\u{1f469}\u{1f3fd}\u200d\u{1f52c}';
      final next = insertChatEmoji(value, emoji);
      expect(next.text, 'ab${emoji}cd');
      expect(next.selection.baseOffset, 2 + emoji.length);
      const family = '\u{1f468}\u200d\u{1f469}\u200d\u{1f467}\u200d\u{1f466}';
      expect(
        insertChatEmoji(const TextEditingValue(text: 'hi'), family).text,
        'hi$family',
      );
    },
  );
  test(
    'emoji cannot exceed backend code point limit or truncate a sequence',
    () {
      final value = TextEditingValue(
        text: 'a' * 1999,
        selection: const TextSelection.collapsed(offset: 1999),
      );
      expect(
        insertChatEmoji(value, '\u{1f469}\u{1f3fd}\u200d\u{1f52c}'),
        value,
      );
      expect(insertChatEmoji(value, '\u{1f600}').text.runes.length, 2000);
    },
  );
  test('image and voice projection retain generic fallbacks without URLs', () {
    final message = ChatMessageDto.fromJson({
      'id': 'message',
      'senderUserId': 'sender',
      'body': 'Voice message',
      'createdAt': '2026-10-03T12:00:00Z',
      'sequence': 1,
      'mine': false,
      'type': 'VOICE',
      'attachment': {'type': 'VOICE', 'size': 1024, 'durationMs': 2000},
    });
    expect(message.body, 'Voice message');
    expect(message.attachment!.durationMs, 2000);
    expect(message.attachment!.width, isNull);
  });
  testWidgets(
    'unconfigured push has localized unavailable state and disabled enable control',
    (tester) async {
      await tester.pumpWidget(
        localizedTestApp(home: const Scaffold(body: PushDeviceControls())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enable on this device'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _DeniedDownload implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    'unavailable',
    403,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}
