import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectChatSocket(Uri uri, String? cookieHeader) {
  return WebSocketChannel.connect(uri);
}
