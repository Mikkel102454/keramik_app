import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/repositories/account_repository.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class ExportAdapter implements HttpClientAdapter {
  ExportAdapter(this.body);
  final ResponseBody Function(RequestOptions options) body;
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    expect(options.responseType, ResponseType.stream);
    return body(options);
  }

  @override
  void close({bool force = false}) {}
}

class LateExportAdapter extends ExportAdapter {
  LateExportAdapter() : super((_) => throw StateError('Use delayed response'));
  final started = Completer<void>();
  final response = Completer<ResponseBody>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    started.complete();
    return response.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory directory;
  late HttpOverrides? previousOverrides;
  late int expired;
  final zip = smallZip();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('export-download-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    await ApiClient.init();
    ApiClient.dio.options.baseUrl = 'http://127.0.0.1';
    expired = 0;
    ApiClient.onUnauthorized = () => expired++;
  });

  tearDown(() async {
    ApiClient.dio.close(force: true);
    ApiClient.onUnauthorized = null;
    HttpOverrides.global = previousOverrides;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  List<Directory> attempts() => directory
      .listSync()
      .whereType<Directory>()
      .where((entry) => entry.path.contains('keramik-export-'))
      .toList();

  void useBytes(List<int> bytes, {int? length, int status = 200}) {
    ApiClient.dio.httpClientAdapter = ExportAdapter(
      (_) => ResponseBody.fromBytes(
        bytes,
        status,
        headers: {
          if (length != null) Headers.contentLengthHeader: ['$length'],
          Headers.contentTypeHeader: ['application/zip'],
        },
      ),
    );
  }

  Future<HttpServer> server() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    ApiClient.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
    ApiClient.dio.httpClientAdapter = IOHttpClientAdapter();
    return server;
  }

  test(
    'exact ZIP is privately published with a unique filename per attempt',
    () async {
      useBytes(zip, length: zip.length);
      final first = await AccountRepository.downloadExport('synthetic');
      final second = await AccountRepository.downloadExport('synthetic');
      expect(first.path, isNot(second.path));
      expect(first.path, startsWith(directory.path));
      expect(first.path, endsWith('/keramik-data-synthetic.zip'));
      expect(await first.readAsBytes(), zip);
      expect(await second.readAsBytes(), zip);
      expect(attempts(), hasLength(2));
      expect(
        directory
            .listSync(recursive: true)
            .where((f) => f.path.endsWith('.part')),
        isEmpty,
      );
    },
  );

  test(
    'failed retry preserves completed file and a later retry succeeds',
    () async {
      useBytes(zip, length: zip.length);
      final first = await AccountRepository.downloadExport('synthetic');
      useBytes(zip.sublist(0, 10), length: zip.length);
      await expectLater(
        AccountRepository.downloadExport('synthetic'),
        throwsA(isA<ApiException>()),
      );
      expect(attempts(), hasLength(1));
      expect(await first.readAsBytes(), zip);
      useBytes(zip, length: zip.length);
      final retried = await AccountRepository.downloadExport('synthetic');
      expect(await retried.readAsBytes(), zip);
      expect(await first.readAsBytes(), zip);
      expect(retried.path, isNot(first.path));
    },
  );

  test(
    'underflow, overflow and malformed lengths remove only the attempt',
    () async {
      for (final length in [zip.length - 1, zip.length + 1]) {
        useBytes(zip, length: length);
        await expectLater(
          AccountRepository.downloadExport('synthetic'),
          throwsA(isA<ApiException>()),
        );
        expect(attempts(), isEmpty);
      }
      ApiClient.dio.httpClientAdapter = ExportAdapter(
        (_) => ResponseBody.fromBytes(
          zip,
          200,
          headers: {
            Headers.contentLengthHeader: ['bad'],
          },
        ),
      );
      await expectLater(
        AccountRepository.downloadExport('synthetic'),
        throwsA(isA<ApiException>()),
      );
      expect(attempts(), isEmpty);
    },
  );

  test(
    'storage/unavailable/expired errors preserve session; 401 expires it',
    () async {
      final uri = Uri.parse('http://127.0.0.1/api/account/exports');
      await ApiClient.cookieJar.saveFromResponse(uri, [
        Cookie('synthetic-session', 'retained'),
      ]);
      for (final status in [404, 500, 401]) {
        useBytes(
          utf8.encode('{"success":false,"error":{"code":"NOT_FOUND"}}'),
          status: status,
        );
        await expectLater(
          AccountRepository.downloadExport('synthetic'),
          throwsA(isA<ApiException>()),
        );
        expect(attempts(), isEmpty);
        expect(
          (await ApiClient.cookieJar.loadForRequest(uri)).single.value,
          'retained',
        );
        expect(expired, status == 401 ? 1 : 0);
      }
    },
  );

  test('interrupted stream cancels storage and removes partial file', () async {
    var cancelled = false;
    final source = StreamController<Uint8List>(
      onCancel: () => cancelled = true,
    );
    source.onListen = () {
      source.add(Uint8List.fromList(zip.sublist(0, 10)));
      source.addError(const SocketException('synthetic interrupted transfer'));
    };
    ApiClient.dio.httpClientAdapter = ExportAdapter(
      (_) => ResponseBody(source.stream, 200),
    );
    await expectLater(
      AccountRepository.downloadExport('synthetic'),
      throwsA(isA<SocketException>()),
    );
    expect(cancelled, isTrue);
    expect(attempts(), isEmpty);
    await source.close();
  });

  test(
    'explicit cancellation removes a written partial and cancels source',
    () async {
      var cancelled = false;
      final source = StreamController<Uint8List>(
        onCancel: () => cancelled = true,
      );
      source.onListen = () => source.add(Uint8List(65536));
      ApiClient.dio.httpClientAdapter = ExportAdapter(
        (_) => ResponseBody(source.stream, 200),
      );
      final token = CancelToken();
      final transfer = AccountRepository.downloadExport(
        'synthetic',
        cancelToken: token,
      );
      final assertion = expectLater(
        transfer,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      for (var i = 0; i < 200; i++) {
        if (directory
            .listSync(recursive: true)
            .whereType<File>()
            .any((f) => f.path.endsWith('.part') && f.lengthSync() > 0)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(attempts(), hasLength(1));
      token.cancel('synthetic cancellation');
      await assertion;
      expect(cancelled, isTrue);
      expect(attempts(), isEmpty);
      await source.close();
    },
  );

  test(
    'cancellation before headers also closes a late transport response',
    () async {
      final adapter = LateExportAdapter();
      ApiClient.dio.httpClientAdapter = adapter;
      final cancelled = Completer<void>();
      final source = StreamController<Uint8List>(onCancel: cancelled.complete);
      final token = CancelToken();
      final assertion = expectLater(
        AccountRepository.downloadExport('synthetic', cancelToken: token),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      await adapter.started.future;
      token.cancel('synthetic cancellation before headers');
      await assertion;
      adapter.response.complete(ResponseBody(source.stream, 200));
      await cancelled.future.timeout(const Duration(seconds: 2));
      expect(attempts(), isEmpty);
      await source.close();
    },
  );

  test(
    'real progressing download may exceed receive inactivity limit',
    () async {
      final local = await server();
      ApiClient.dio.options.receiveTimeout = const Duration(milliseconds: 300);
      local.listen((request) async {
        request.response.bufferOutput = false;
        request.response.headers.contentType = ContentType(
          'application',
          'zip',
        );
        for (var i = 0; i < zip.length; i += 30) {
          request.response.add(
            zip.sublist(i, i + 30 > zip.length ? zip.length : i + 30),
          );
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        await request.response.close();
      });
      final elapsed = Stopwatch()..start();
      final file = await AccountRepository.downloadExport('synthetic');
      expect(elapsed.elapsed, greaterThan(const Duration(milliseconds: 300)));
      expect(await file.readAsBytes(), zip);
    },
  );

  test('real chunked response preserves ZIP and shared cookies', () async {
    final local = await server();
    final uri = Uri.parse(ApiClient.dio.options.baseUrl);
    await ApiClient.cookieJar.saveFromResponse(uri, [
      Cookie('synthetic-session', 'retained'),
    ]);
    final served = Completer<void>();
    local.listen((request) async {
      try {
        expect(request.uri.path, '/api/account/exports/synthetic/download');
        expect(request.cookies.single.value, 'retained');
        request.response.headers.contentType = ContentType(
          'application',
          'zip',
        );
        request.response.headers.chunkedTransferEncoding = true;
        for (var i = 0; i < zip.length; i += 7) {
          request.response.add(
            zip.sublist(i, i + 7 > zip.length ? zip.length : i + 7),
          );
          await request.response.flush();
        }
        await request.response.close();
        served.complete();
      } catch (error, stack) {
        served.completeError(error, stack);
      }
    });
    final file = await AccountRepository.downloadExport('synthetic');
    await served.future;
    expect(await file.readAsBytes(), zip);
    expect(expired, 0);
  });

  for (final afterHeaders in [false, true]) {
    test(
      'real receive timeout ${afterHeaders ? 'mid-body' : 'before headers'} cleans partial and preserves session',
      () async {
        final local = await server();
        ApiClient.dio.options.receiveTimeout = const Duration(
          milliseconds: 100,
        );
        local.listen((request) async {
          if (afterHeaders) {
            request.response.headers.contentType = ContentType(
              'application',
              'zip',
            );
            request.response.add(zip.sublist(0, 10));
            await request.response.flush();
          }
          // Deliberately stalled isolated connection, closed by test teardown.
        });
        await expectLater(
          AccountRepository.downloadExport('synthetic'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.receiveTimeout,
            ),
          ),
        );
        expect(attempts(), isEmpty);
        expect(expired, 0);
      },
    );
  }

  test(
    'real premature HTTP EOF is rejected and its partial is removed',
    () async {
      final local = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(local.close);
      ApiClient.dio.options.baseUrl = 'http://127.0.0.1:${local.port}';
      ApiClient.dio.httpClientAdapter = IOHttpClientAdapter();
      local.listen((socket) {
        socket.listen((_) async {
          socket.add(
            utf8.encode(
              'HTTP/1.1 200 OK\r\nContent-Type: application/zip\r\nContent-Length: ${zip.length}\r\nConnection: close\r\n\r\n',
            ),
          );
          socket.add(zip.sublist(0, 10));
          await socket.flush();
          await socket.close();
        });
      });
      await expectLater(
        AccountRepository.downloadExport('synthetic'),
        throwsA(anything),
      );
      expect(attempts(), isEmpty);
      expect(expired, 0);
    },
  );

  test(
    '128 MiB valid generated ZIP keeps producer at most one chunk ahead of disk',
    () async {
      const payloadLength = 128 * 1024 * 1024;
      final envelope = zipEnvelope(
        payloadLength,
        0x80654151,
      ); // CRC32 of 128 MiB of zeroes
      final block = Uint8List(65536);
      var produced = 0;
      var maxAhead = 0;
      int written() => directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.part'))
          .fold(0, (sum, file) => sum + file.lengthSync());
      Stream<Uint8List> fixture() async* {
        for (final chunk in [envelope.$1]) {
          produced += chunk.length;
          yield chunk;
        }
        for (var i = 0; i < payloadLength ~/ block.length; i++) {
          final ahead = produced - written();
          if (ahead > maxAhead) maxAhead = ahead;
          expect(ahead, lessThanOrEqualTo(block.length));
          produced += block.length;
          yield block;
        }
        produced += envelope.$2.length;
        yield envelope.$2;
      }

      final length = payloadLength + envelope.$1.length + envelope.$2.length;
      ApiClient.dio.httpClientAdapter = ExportAdapter(
        (_) => ResponseBody(
          fixture(),
          200,
          headers: {
            Headers.contentLengthHeader: ['$length'],
          },
        ),
      );
      final file = await AccountRepository.downloadExport('large-synthetic');
      expect(await file.length(), length);
      final reader = await file.open();
      try {
        expect(await reader.read(envelope.$1.length), envelope.$1);
        await reader.setPosition(envelope.$1.length + payloadLength);
        expect(await reader.read(envelope.$2.length), envelope.$2);
      } finally {
        await reader.close();
      }
      expect(maxAhead, lessThanOrEqualTo(65536));
      expect(produced, length);
      // Consume the resulting file in bounded blocks, checking the entire payload.
      var offset = 0;
      await for (final chunk in file.openRead(
        envelope.$1.length,
        envelope.$1.length + payloadLength,
      )) {
        expect(chunk.any((byte) => byte != 0), isFalse);
        offset += chunk.length;
      }
      expect(offset, payloadLength);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Uint8List smallZip() {
  final payload = utf8.encode('{"synthetic":true}');
  var crc = 0xffffffff;
  for (final byte in payload) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
    }
  }
  final envelope = zipEnvelope(payload.length, crc ^ 0xffffffff);
  return Uint8List.fromList([...envelope.$1, ...payload, ...envelope.$2]);
}

/// A single-entry STORED ZIP, generated as header / bounded payload / directory.
(Uint8List, Uint8List) zipEnvelope(int length, int crc) {
  final name = utf8.encode('synthetic.bin');
  final header = ByteData(30 + name.length);
  header.setUint32(0, 0x04034b50, Endian.little);
  header.setUint16(4, 20, Endian.little);
  header.setUint32(14, crc, Endian.little);
  header.setUint32(18, length, Endian.little);
  header.setUint32(22, length, Endian.little);
  header.setUint16(26, name.length, Endian.little);
  header.buffer.asUint8List().setRange(30, 30 + name.length, name);
  final tail = ByteData(46 + name.length + 22);
  tail.setUint32(0, 0x02014b50, Endian.little);
  tail.setUint16(4, 20, Endian.little);
  tail.setUint16(6, 20, Endian.little);
  tail.setUint32(16, crc, Endian.little);
  tail.setUint32(20, length, Endian.little);
  tail.setUint32(24, length, Endian.little);
  tail.setUint16(28, name.length, Endian.little);
  tail.buffer.asUint8List().setRange(46, 46 + name.length, name);
  final end = 46 + name.length;
  tail.setUint32(end, 0x06054b50, Endian.little);
  tail.setUint16(end + 8, 1, Endian.little);
  tail.setUint16(end + 10, 1, Endian.little);
  tail.setUint32(end + 12, end, Endian.little);
  tail.setUint32(end + 16, header.lengthInBytes + length, Endian.little);
  return (header.buffer.asUint8List(), tail.buffer.asUint8List());
}
