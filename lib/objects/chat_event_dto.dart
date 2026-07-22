class ChatEventDto {
  const ChatEventDto({
    required this.eventId,
    required this.type,
    required this.occurredAt,
    this.conversationType,
    this.conversationId,
    this.reconcileOnly = false,
  });

  final String eventId;
  final String type;
  final String? conversationType;
  final String? conversationId;
  final DateTime occurredAt;
  final bool reconcileOnly;

  factory ChatEventDto.fromJson(Map<String, dynamic> json) {
    final eventId = json['eventId'];
    final type = json['type'];
    final occurredAt = json['occurredAt'];
    if (eventId is! String ||
        eventId.isEmpty ||
        type is! String ||
        occurredAt is! String) {
      throw const FormatException('Invalid chat event');
    }
    return ChatEventDto(
      eventId: eventId,
      type: type,
      conversationType: json['conversationType'] as String?,
      conversationId: json['conversationId'] as String?,
      occurredAt: DateTime.parse(occurredAt).toLocal(),
    );
  }

  factory ChatEventDto.reconcile() => ChatEventDto(
    eventId: '',
    type: 'SYNC_REQUIRED',
    occurredAt: DateTime.now(),
    reconcileOnly: true,
  );
}

class ChatEventDeduplicator {
  ChatEventDeduplicator({this.capacity = 500});

  final int capacity;
  final Set<String> _seen = <String>{};
  final List<String> _order = <String>[];

  bool accept(String eventId) {
    if (eventId.isEmpty || _seen.contains(eventId)) return false;
    _seen.add(eventId);
    _order.add(eventId);
    if (_order.length > capacity) _seen.remove(_order.removeAt(0));
    return true;
  }

  void clear() {
    _seen.clear();
    _order.clear();
  }
}
