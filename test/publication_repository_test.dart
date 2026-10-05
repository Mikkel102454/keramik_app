import 'dart:convert';
import 'dart:typed_data';

import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/repositories/publication_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RecordingAdapter adapter;

  setUp(() {
    adapter = _RecordingAdapter();
    ApiClient.dio = Dio()..httpClientAdapter = adapter;
  });

  test('Not interested uses PUT and Undo uses DELETE', () async {
    await PublicationRepository.notInterested('publication-id', true);
    await PublicationRepository.notInterested('publication-id', false);

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests[0].method, 'PUT');
    expect(adapter.requests[1].method, 'DELETE');
    expect(
      adapter.requests.map((request) => request.path),
      everyElement('/api/discover/publication-id/not-interested'),
    );
  });

  test('Discover forwards the controller logical request ID unchanged', () async {
    const requestId = '5b319c83-f300-4b4d-b84a-eac4dd96a778';

    await PublicationRepository.discover(
      'LATEST',
      cursor: 'opaque-cursor',
      requestId: requestId,
    );

    final request = adapter.requests.single;
    expect(request.path, '/api/discover');
    expect(request.queryParameters['mode'], 'LATEST');
    expect(request.queryParameters['cursor'], 'opaque-cursor');
    expect(request.queryParameters['requestId'], requestId);
  });

  test(
    'report sends a stable category, trimmed explanation, and client UUID',
    () async {
      final receipt = await PublicationRepository.report(
        'publication-id',
        'OTHER',
        '  enough context  ',
      );

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/discover/publication-id/reports');
      expect(request.data, isA<Map<String, dynamic>>());
      final data = request.data as Map<String, dynamic>;
      expect(data['category'], 'OTHER');
      expect(data['explanation'], 'enough context');
      expect(
        data['clientReportId'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(receipt.reportId, 'report-id');
      expect(receipt.evidenceState, 'EVIDENCE_PENDING');
      expect(receipt.replayed, isFalse);
    },
  );

  test('duplicate report receipt is surfaced as a replay', () async {
    adapter = _RecordingAdapter(replayed: true);
    ApiClient.dio = Dio()..httpClientAdapter = adapter;

    final receipt = await PublicationRepository.report(
      'publication-id',
      'SPAM',
      '',
    );

    expect(receipt.reportId, 'report-id');
    expect(receipt.replayed, isTrue);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.replayed = false});

  final bool replayed;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = options.path == '/api/discover'
        ? {'items': <Object>[], 'nextCursor': null}
        : {
            'reportId': 'report-id',
            'evidenceState': 'EVIDENCE_PENDING',
            'createdAt': '2026-07-25T12:00:00Z',
            'replayed': replayed,
          };
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': data,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
