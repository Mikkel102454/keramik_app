import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectChatSocket(Uri uri, String? cookieHeader) {
  return IOWebSocketChannel.connect(
    uri,
    headers: cookieHeader == null ? null : {'Cookie': cookieHeader},
    connectTimeout: const Duration(seconds: 10),
  );
}
