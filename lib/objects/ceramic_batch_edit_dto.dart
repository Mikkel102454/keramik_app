class CeramicBatchEditSpec {
  CeramicBatchEditSpec({
    this.stageId,
    this.clayMode = 'KEEP',
    this.clayId,
    this.addTags = const [],
    this.removeTags = const [],
    this.heightCm,
    this.widthCm,
    this.depthCm,
    this.diameterCm,
    this.planningTemplateId,
    this.applyGlazes = false,
    this.applyFirings = false,
  });

  int? stageId;
  String clayMode;
  int? clayId;
  List<String> addTags;
  List<String> removeTags;
  double? heightCm;
  double? widthCm;
  double? depthCm;
  double? diameterCm;
  int? planningTemplateId;
  bool applyGlazes;
  bool applyFirings;

  Map<String, dynamic> toJson() => {
    'stageId': stageId,
    'clayChange': clayMode == 'KEEP'
        ? null
        : {'mode': clayMode, 'clayId': clayId},
    'addTags': addTags,
    'removeTags': removeTags,
    'dimensions':
        heightCm == null &&
            widthCm == null &&
            depthCm == null &&
            diameterCm == null
        ? null
        : {
            'heightCm': heightCm,
            'widthCm': widthCm,
            'depthCm': depthCm,
            'diameterCm': diameterCm,
          },
    'planningTemplateId': planningTemplateId,
    'applyGlazes': applyGlazes,
    'applyFirings': applyFirings,
  };
}

class CeramicBatchTargetDto {
  const CeramicBatchTargetDto({
    required this.ceramicId,
    required this.title,
    required this.expectedUpdatedAt,
    required this.warnings,
  });
  final int ceramicId;
  final String title;
  final DateTime expectedUpdatedAt;
  final List<String> warnings;

  factory CeramicBatchTargetDto.fromJson(Map<String, dynamic> json) =>
      CeramicBatchTargetDto(
        ceramicId: json['ceramicId'] as int,
        title: json['title'] as String,
        expectedUpdatedAt: DateTime.parse(json['expectedUpdatedAt'] as String),
        warnings: (json['warnings'] as List? ?? const []).cast<String>(),
      );
}

class CeramicBatchPreviewDto {
  const CeramicBatchPreviewDto({
    required this.selectedCount,
    required this.changes,
    required this.targets,
  });
  final int selectedCount;
  final List<String> changes;
  final List<CeramicBatchTargetDto> targets;

  factory CeramicBatchPreviewDto.fromJson(Map<String, dynamic> json) =>
      CeramicBatchPreviewDto(
        selectedCount: json['selectedCount'] as int,
        changes: (json['changes'] as List).cast<String>(),
        targets: (json['targets'] as List)
            .map((value) => CeramicBatchTargetDto.fromJson(value))
            .toList(),
      );
}

class CeramicBatchResultDto {
  const CeramicBatchResultDto({
    required this.selectedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.targets,
  });
  final int selectedCount;
  final int updatedCount;
  final int skippedCount;
  final List<CeramicBatchResultTargetDto> targets;

  factory CeramicBatchResultDto.fromJson(Map<String, dynamic> json) =>
      CeramicBatchResultDto(
        selectedCount: json['selectedCount'] as int,
        updatedCount: json['updatedCount'] as int,
        skippedCount: json['skippedCount'] as int,
        targets: (json['targets'] as List)
            .map((value) => CeramicBatchResultTargetDto.fromJson(value))
            .toList(),
      );
}

class CeramicBatchResultTargetDto {
  const CeramicBatchResultTargetDto({
    required this.ceramicId,
    required this.title,
    required this.updated,
    required this.status,
    required this.warnings,
  });
  final int ceramicId;
  final String title;
  final bool updated;
  final String status;
  final List<String> warnings;

  factory CeramicBatchResultTargetDto.fromJson(Map<String, dynamic> json) =>
      CeramicBatchResultTargetDto(
        ceramicId: json['ceramicId'] as int,
        title: json['title'] as String,
        updated: json['updated'] as bool,
        status: json['status'] as String,
        warnings: (json['warnings'] as List? ?? const []).cast<String>(),
      );
}
