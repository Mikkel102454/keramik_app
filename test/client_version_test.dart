import 'dart:convert';
import 'dart:typed_data';
import 'package:clay_dock/app/client_version_controller.dart';
import 'package:clay_dock/ui/widgets/client_version_gate.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PolicyAdapter implements HttpClientAdapter {
  int minimum = 1;
  bool fail = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'schemaVersion': 1,
          'latestVersionCode': 2,
          'minimumVersionCode': minimum,
          'availableAt': '2026-10-01T00:00:00Z',
          'mandatoryAt': '2026-10-08T00:00:00Z',
          'storeUrl':
              'https://play.google.com/store/apps/details?id=nu.miguel.claydock',
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'previous client prompts until server minimum advances at shared deadline',
    () async {
      final adapter = _PolicyAdapter();
      final controller = ClientVersionController(
        dio: Dio()..httpClientAdapter = adapter,
        versionCode: 1,
      );
      addTearDown(controller.dispose);
      expect(controller.mayEnter, isFalse);
      await controller.verify();
      expect(controller.mayEnter, isTrue);
      expect(controller.updateAvailable, isTrue);
      adapter.minimum = 2;
      await controller.verify();
      expect(controller.state, VersionVerification.updateRequired);
      expect(controller.mayEnter, isFalse);
    },
  );
  test(
    'failed refresh blocks verification without claiming outdated or losing policy',
    () async {
      final adapter = _PolicyAdapter();
      final controller = ClientVersionController(
        dio: Dio()..httpClientAdapter = adapter,
        versionCode: 2,
      );
      addTearDown(controller.dispose);
      await controller.verify();
      adapter.fail = true;
      await controller.verify();
      expect(controller.state, VersionVerification.unavailable);
      expect(controller.policy?.minimum, 1);
      adapter.fail = false;
      await controller.verify();
      expect(controller.mayEnter, isTrue);
    },
  );
  test(
    'missing installed native identity is unavailable, even if backend says supported',
    () async {
      final controller = ClientVersionController(
        dio: Dio()..httpClientAdapter = _PolicyAdapter(),
        versionCode: 0,
      );
      addTearDown(controller.dispose);
      await controller.verify();
      expect(controller.state, VersionVerification.unavailable);
    },
  );
  test(
    'unknown policy schema, foreign store destination and unequal deadline fail',
    () {
      Map<String, dynamic> valid() => {
        'schemaVersion': 1,
        'latestVersionCode': 2,
        'minimumVersionCode': 1,
        'availableAt': '2026-10-01T00:00:00Z',
        'mandatoryAt': '2026-10-08T00:00:00Z',
        'storeUrl':
            'https://play.google.com/store/apps/details?id=nu.miguel.claydock',
      };
      expect(
        () => ClientPolicy.fromJson(valid()..['schemaVersion'] = 2),
        throwsFormatException,
      );
      expect(
        () => ClientPolicy.fromJson(
          valid()..['storeUrl'] = 'https://example.invalid',
        ),
        throwsFormatException,
      );
      expect(
        () => ClientPolicy.fromJson(
          valid()..['mandatoryAt'] = '2026-10-07T00:00:00Z',
        ),
        throwsFormatException,
      );
    },
  );
  testWidgets('verification overlay preserves mounted entered drafts', (
    tester,
  ) async {
    final adapter = _PolicyAdapter();
    final controller = ClientVersionController(
      dio: Dio()..httpClientAdapter = adapter,
      versionCode: 2,
    );
    final text = TextEditingController(text: 'retained unsent message');
    addTearDown(controller.dispose);
    addTearDown(text.dispose);
    await tester.runAsync(controller.verify);
    await tester.pumpWidget(
      MaterialApp(
        home: ClientVersionGate(
          controller: controller,
          child: Scaffold(body: TextField(controller: text)),
        ),
      ),
    );
    final element = tester.element(find.byType(TextField));
    adapter.fail = true;
    await tester.runAsync(controller.verify);
    await tester.pump();
    expect(find.textContaining('Could not verify'), findsOneWidget);
    expect(identical(element, tester.element(find.byType(TextField))), isTrue);
    expect(text.text, 'retained unsent message');
    adapter.fail = false;
    await tester.runAsync(controller.verify);
    await tester.pump();
    expect(find.textContaining('Could not verify'), findsNothing);
  });
}
