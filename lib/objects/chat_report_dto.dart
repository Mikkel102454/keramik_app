enum ChatReportCategory {
  spam('SPAM', 'Spam'),
  harassment('HARASSMENT', 'Harassment'),
  hate('HATE', 'Hate'),
  sexualContent('SEXUAL_CONTENT', 'Sexual content'),
  violence('VIOLENCE', 'Violence'),
  other('OTHER', 'Other');

  const ChatReportCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum ChatReportValidationError {
  chooseReason,
  otherExplanationRequired,
  explanationTooLong,
}

class ChatReportReceiptDto {
  const ChatReportReceiptDto({required this.reportId, required this.createdAt});

  final String reportId;
  final DateTime createdAt;

  factory ChatReportReceiptDto.fromJson(Map<String, dynamic> json) {
    return ChatReportReceiptDto(
      reportId: json['reportId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

ChatReportValidationError? validateChatReport(
  ChatReportCategory? category,
  String explanation,
) {
  if (category == null) return ChatReportValidationError.chooseReason;
  final trimmed = explanation.trim();
  if (category == ChatReportCategory.other && trimmed.isEmpty) {
    return ChatReportValidationError.otherExplanationRequired;
  }
  if (trimmed.runes.length > 1000) {
    return ChatReportValidationError.explanationTooLong;
  }
  return null;
}
