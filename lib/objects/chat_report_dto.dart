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

String? validateChatReport(ChatReportCategory? category, String explanation) {
  if (category == null) return 'Choose a reason for this report.';
  final trimmed = explanation.trim();
  if (category == ChatReportCategory.other && trimmed.isEmpty) {
    return 'Add an explanation when choosing Other.';
  }
  if (trimmed.runes.length > 1000) {
    return 'The explanation must contain at most 1000 characters.';
  }
  return null;
}
