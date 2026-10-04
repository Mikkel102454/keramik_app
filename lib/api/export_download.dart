import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ceramic_app/utils/web.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Each attempt owns a unique private directory. A completed file is returned
/// only after EOF, length validation and closing the file, never overwritten.
Future<File> downloadExportFile(
  Dio client,
  String id, {
  CancelToken? cancelToken,
}) async {
  final token = cancelToken ?? CancelToken();
  final adapter = _DownloadAdapter(client.httpClientAdapter);
  // Keep the same cookie/session interceptors, options and transport. Closing
  // this clone must not close the shared adapter used by other requests.
  final downloadClient = client.clone(httpClientAdapter: adapter);
  Directory? attempt;
  RandomAccessFile? output;
  var complete = false;
  try {
    final response = await downloadClient.get<ResponseBody>(
      '/api/account/exports/$id/download',
      options: Options(responseType: ResponseType.stream),
      cancelToken: token,
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const ApiException('The export could not be downloaded');
    }
    final lengthHeader = response.headers.value(Headers.contentLengthHeader);
    final expected = lengthHeader == null ? null : int.tryParse(lengthHeader);
    if (lengthHeader != null && (expected == null || expected < 0)) {
      throw const ApiException('The export could not be downloaded');
    }
    final directory = await getTemporaryDirectory();
    attempt = await directory.createTemp('keramik-export-');
    final filename =
        'keramik-data-${id.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '_')}.zip';
    final partial = File('${attempt.path}/$filename.part');
    output = await partial.open(mode: FileMode.write);
    var received = 0;
    await for (final chunk in response.data!.stream) {
      if (token.isCancelled) throw token.cancelError!;
      received += chunk.length;
      if (expected != null && received > expected) {
        throw const ApiException('The export transfer was incomplete');
      }
      await output.writeFrom(chunk);
      adapter.acknowledge();
    }
    if (expected != null && received != expected) {
      throw const ApiException('The export transfer was incomplete');
    }
    await output.flush();
    await output.close();
    output = null;
    if (token.isCancelled) throw token.cancelError!;
    final file = await partial.rename('${attempt.path}/$filename');
    if (token.isCancelled) throw token.cancelError!;
    complete = true;
    return file;
  } finally {
    if (!complete && !token.isCancelled) token.cancel('Export download ended');
    try {
      await adapter.dispose();
    } finally {
      downloadClient.close();
      try {
        await output?.close();
      } finally {
        if (!complete && attempt != null) await attempt.delete(recursive: true);
      }
    }
  }
}

/// Dio 5.9's response wrapper eagerly listens without forwarding pause/resume.
/// Gate the transport BEFORE that wrapper so it can queue at most one chunk.
/// Disk writes acknowledge chunks; the raw socket stream stays paused meanwhile.
class _DownloadAdapter implements HttpClientAdapter {
  _DownloadAdapter(this.transport);
  final HttpClientAdapter transport;
  StreamIterator<Uint8List>? _source;
  Completer<void>? _written;
  bool _disposed = false;

  void acknowledge() {
    final written = _written;
    if (written != null && !written.isCompleted) written.complete();
  }

  Stream<Uint8List> _chunks(
    StreamIterator<Uint8List> source,
    RequestOptions options,
  ) async* {
    final timeout = options.receiveTimeout ?? Duration.zero;
    Future<bool> next() {
      final pending = source.moveNext();
      // Dio starts its body timer only after the first data event. Apply the
      // same inactivity limit while waiting for the first body chunk as well.
      return timeout > Duration.zero
          ? pending.timeout(
              timeout,
              onTimeout: () => throw DioException.receiveTimeout(
                timeout: timeout,
                requestOptions: options,
              ),
            )
          : pending;
    }

    try {
      while (!_disposed && await next()) {
        if (_disposed) break;
        final written = _written = Completer<void>();
        yield source.current;
        await written.future;
      }
    } finally {
      await source.cancel();
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = await transport.fetch(options, requestStream, cancelFuture);
    if (_disposed) {
      // Cancellation can finish Dio's request before a late adapter response.
      // Release that response too, without ever publishing a file.
      await body.stream.listen(null).cancel();
      body.stream = const Stream.empty();
      return body;
    }
    final source = _source = StreamIterator(body.stream);
    body.stream = _chunks(source, options);
    return body;
  }

  Future<void> dispose() async {
    _disposed = true;
    acknowledge();
    await _source?.cancel();
  }

  @override
  void close({bool force = false}) {} // The shared transport belongs to ApiClient.
}
