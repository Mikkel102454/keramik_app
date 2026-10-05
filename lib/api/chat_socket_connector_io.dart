import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:clay_dock/app/client_version_controller.dart';

WebSocketChannel connectChatSocket(Uri uri, String? cookieHeader) {
  return IOWebSocketChannel.connect(
    uri,
    headers: {...InstalledClient.headers, 'Cookie': ?cookieHeader},
    connectTimeout: const Duration(seconds: 10),
  );
}
