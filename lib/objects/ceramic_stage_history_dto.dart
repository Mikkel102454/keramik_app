class CeramicStageHistoryDto {
  const CeramicStageHistoryDto({
    required this.id,
    required this.fromStageId,
    required this.fromStageTitle,
    required this.toStageId,
    required this.toStageTitle,
    required this.changedAt,
    required this.baseline,
  });

  final int id;
  final int? fromStageId;
  final String? fromStageTitle;
  final int toStageId;
  final String toStageTitle;
  final DateTime changedAt;
  final bool baseline;

  factory CeramicStageHistoryDto.fromJson(Map<String, dynamic> json) {
    return CeramicStageHistoryDto(
      id: json['id'] as int,
      fromStageId: json['fromStageId'] as int?,
      fromStageTitle: json['fromStageTitle'] as String?,
      toStageId: json['toStageId'] as int,
      toStageTitle: json['toStageTitle'] as String,
      changedAt: DateTime.parse(json['changedAt'] as String),
      baseline: json['baseline'] as bool? ?? false,
    );
  }
}
