class CeramicBatchDeleteTargetDto {
  const CeramicBatchDeleteTargetDto({
    required this.ceramicId,
    required this.title,
    required this.expectedUpdatedAt,
  });

  final int ceramicId;
  final String title;
  final DateTime expectedUpdatedAt;

  factory CeramicBatchDeleteTargetDto.fromJson(Map<String, dynamic> json) =>
      CeramicBatchDeleteTargetDto(
        ceramicId: json['ceramicId'] as int,
        title: json['title'] as String,
        expectedUpdatedAt: DateTime.parse(json['expectedUpdatedAt'] as String),
      );

  Map<String, dynamic> toApplyJson() => {
    'ceramicId': ceramicId,
    'expectedUpdatedAt': expectedUpdatedAt.toIso8601String(),
  };
}

class CeramicBatchDeletePreviewDto {
  const CeramicBatchDeletePreviewDto({
    required this.selectedCount,
    required this.targets,
  });

  final int selectedCount;
  final List<CeramicBatchDeleteTargetDto> targets;

  factory CeramicBatchDeletePreviewDto.fromJson(Map<String, dynamic> json) =>
      CeramicBatchDeletePreviewDto(
        selectedCount: json['selectedCount'] as int,
        targets: (json['targets'] as List)
            .map(
              (value) => CeramicBatchDeleteTargetDto.fromJson(
                value as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
}

class CeramicBatchDeleteResultDto {
  const CeramicBatchDeleteResultDto({
    required this.deletedCount,
    required this.targets,
  });

  final int deletedCount;
  final List<CeramicBatchDeletedTargetDto> targets;

  factory CeramicBatchDeleteResultDto.fromJson(Map<String, dynamic> json) =>
      CeramicBatchDeleteResultDto(
        deletedCount: json['deletedCount'] as int,
        targets: (json['targets'] as List)
            .map(
              (value) => CeramicBatchDeletedTargetDto.fromJson(
                value as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
}

class CeramicBatchDeletedTargetDto {
  const CeramicBatchDeletedTargetDto({
    required this.ceramicId,
    required this.title,
  });

  final int ceramicId;
  final String title;

  factory CeramicBatchDeletedTargetDto.fromJson(Map<String, dynamic> json) =>
      CeramicBatchDeletedTargetDto(
        ceramicId: json['ceramicId'] as int,
        title: json['title'] as String,
      );
}
