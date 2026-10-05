import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/chat_dto.dart';
import 'package:clay_dock/ui/pages/notification/add_group_members_page.dart';
import 'package:clay_dock/ui/pages/settings/account_settings_pages.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  late _Adapter adapter;
  setUp(() {
    adapter = _Adapter();
    ApiClient.dio = Dio(
      BaseOptions(
        baseUrl: 'https://isolated.test',
        validateStatus: (_) => true,
      ),
    )..httpClientAdapter = adapter;
  });
  tearDown(() => ApiClient.dio.close(force: true));

  testWidgets('password failure is safe and keeps the draft for retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: const PasswordSecurityPage()),
    );
    await tester.enterText(find.byType(TextField).at(0), 'old-password');
    await tester.enterText(find.byType(TextField).at(1), 'new-password');
    await tester.enterText(find.byType(TextField).at(2), 'new-password');
    await tester.ensureVisible(find.text('Change password'));
    await tester.pump();
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    expect(
      find.text('Password could not be changed. Please retry.'),
      findsOneWidget,
    );
    expect(find.textContaining('private backend detail'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'old-password',
    );
    await tester.ensureVisible(find.text('Change password'));
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    expect(adapter.passwordCalls, 2);
    expect(
      find.text('Password changed. Other sessions have been signed out.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
  });

  testWidgets('export request and job errors never expose server details', (
    tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(home: const DataExportPage()));
    await tester.tap(find.text('Create export'));
    await tester.pumpAndSettle();
    expect(find.text('The export could not be requested.'), findsOneWidget);
    expect(find.textContaining('private backend detail'), findsNothing);
    await tester.tap(find.text('Create export'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Refresh status'));
    await tester.pumpAndSettle();
    expect(find.text('Export failed'), findsWidgets);
    expect(find.textContaining('private export storage detail'), findsNothing);
    expect(adapter.exportCalls, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('failed group friend loading retries and builds members lazily', (
    tester,
  ) async {
    adapter.friendsRetry = Completer<ResponseBody>();
    final group = DirectConversationDto.fromJson({
      'id': 'group-id',
      'status': 'ACTIVE',
      'type': 'GROUP',
      'title': 'Studio',
      'avatarInitials': 'ST',
      'avatarColor': '#355070',
      'unreadCount': 0,
      'archived': false,
      'incomingRequest': false,
      'readOnly': false,
      'memberCount': 49,
    });
    await tester.pumpWidget(
      localizedTestApp(home: AddGroupMembersPage(group: group)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('private backend detail'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    adapter.friendsRetry!.complete(
      adapter.response({
        'items': List.generate(
          100,
          (index) => {
            'userId': 'friend-$index',
            'username': 'potter-$index',
            'avatarInitials': 'PO',
            'avatarColor': '#355070',
            'relationshipState': 'FRIENDS',
            'actions': <String>[],
          },
        ),
        'nextCursor': null,
      }),
    );
    await tester.pumpAndSettle();
    expect(adapter.friendCalls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('potter-0'), findsOneWidget);
    expect(find.text('potter-99'), findsNothing);
    await tester.tap(find.text('potter-0'));
    await tester.pump();
    final next = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'potter-1'),
    );
    expect(next.onChanged, isNull);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'potter-0'),
          )
          .value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}

class _Adapter implements HttpClientAdapter {
  int passwordCalls = 0;
  int exportCalls = 0;
  int friendCalls = 0;
  Completer<ResponseBody>? friendsRetry;

  ResponseBody response(dynamic data, {bool success = true}) =>
      ResponseBody.fromString(
        jsonEncode({
          'success': success,
          'data': data,
          if (!success) 'error': {'message': 'private backend detail'},
        }),
        success ? 200 : 500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/account/password') {
      return response(null, success: ++passwordCalls > 1);
    }
    if (options.path == '/api/account/exports') {
      if (++exportCalls == 1) return response(null, success: false);
      return response({
        'exportId': 'export-id',
        'status': 'PENDING',
        'createdAt': '2026-10-04T10:00:00Z',
        'downloadAvailable': false,
      });
    }
    if (options.path == '/api/account/exports/export-id') {
      return response({
        'exportId': 'export-id',
        'status': 'FAILED',
        'createdAt': '2026-10-04T10:00:00Z',
        'downloadAvailable': false,
        'errorMessage': 'private export storage detail',
      });
    }
    if (options.path == '/api/friends') {
      if (++friendCalls == 1) return response(null, success: false);
      return friendsRetry!.future;
    }
    throw StateError('Unexpected isolated request: ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}
