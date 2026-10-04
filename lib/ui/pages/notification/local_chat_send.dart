import 'dart:io';

import 'package:ceramic_app/objects/chat_dto.dart';

/// Session-only delivery state. Local previews never enter server history,
/// pagination, read markers, reporting or shared-card navigation.
class LocalChatSend {
  LocalChatSend({
    required this.clientId,
    required this.message,
    required this.retry,
    this.file,
    this.ownsFile = false,
  });

  final String clientId;
  final ChatMessageDto message;
  final Future<void> Function() retry;
  final File? file;
  final bool ownsFile;
  bool failed = false;
  bool unconfirmed = false;
  bool inFlight = true;
  // First-send endpoints return a conversation; keep its preview if history
  // refresh fails after that successful response, until REST supplies the row.
  bool acknowledged = false;
}
