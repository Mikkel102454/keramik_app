class ProjectTemplateDto {
  ProjectTemplateDto({
    required this.id,
    required this.version,
    required this.name,
    required this.titlePattern,
    required this.note,
    required this.tags,
    required this.glazes,
    required this.firings,
    this.clayId,
    this.clayTitle,
    this.clayAvailable = true,
    this.heightCm,
    this.widthCm,
    this.depthCm,
    this.diameterCm,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int version;
  String name;
  String titlePattern;
  int? clayId;
  String? clayTitle;
  bool clayAvailable;
  String note;
  double? heightCm;
  double? widthCm;
  double? depthCm;
  double? diameterCm;
  List<String> tags;
  List<TemplateGlazeDto> glazes;
  List<TemplateFiringDto> firings;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory ProjectTemplateDto.fromJson(Map<String, dynamic> json) {
    return ProjectTemplateDto(
      id: (json['id'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      name: json['name'] as String,
      titlePattern: json['titlePattern'] as String,
      clayId: (json['clayId'] as num?)?.toInt(),
      clayTitle: json['clayTitle'] as String?,
      clayAvailable: json['clayAvailable'] as bool? ?? true,
      note: json['note'] as String? ?? '',
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      widthCm: (json['widthCm'] as num?)?.toDouble(),
      depthCm: (json['depthCm'] as num?)?.toDouble(),
      diameterCm: (json['diameterCm'] as num?)?.toDouble(),
      tags: (json['tags'] as List? ?? const []).cast<String>(),
      glazes: (json['glazes'] as List? ?? const [])
          .map((value) => TemplateGlazeDto.fromJson(value))
          .toList(),
      firings: (json['firings'] as List? ?? const [])
          .map((value) => TemplateFiringDto.fromJson(value))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toRequestJson() => {
    'name': name,
    'titlePattern': titlePattern,
    'clayId': clayId ?? 0,
    'note': note,
    'heightCm': heightCm,
    'widthCm': widthCm,
    'depthCm': depthCm,
    'diameterCm': diameterCm,
    'tags': tags,
    'glazes': glazes.map((value) => value.toRequestJson()).toList(),
    'firings': firings.map((value) => value.toRequestJson()).toList(),
    'expectedVersion': version,
  };
}

class TemplateGlazeDto {
  TemplateGlazeDto({
    required this.glazeId,
    required this.glazeTitle,
    required this.note,
    required this.layerOrder,
    required this.coatCount,
    this.available = true,
  });

  final int? glazeId;
  final String glazeTitle;
  final bool available;
  String note;
  int layerOrder;
  int coatCount;

  factory TemplateGlazeDto.fromJson(Map<String, dynamic> json) =>
      TemplateGlazeDto(
        glazeId: (json['glazeId'] as num?)?.toInt(),
        glazeTitle: json['glazeTitle'] as String? ?? '',
        available: json['available'] as bool? ?? true,
        note: json['note'] as String? ?? '',
        layerOrder: json['layerOrder'] as int? ?? 1,
        coatCount: json['coatCount'] as int? ?? 1,
      );

  Map<String, dynamic> toRequestJson() => {
    'glazeId': glazeId,
    'note': note,
    'layerOrder': layerOrder,
    'coatCount': coatCount,
  };
}

class TemplateFiringDto {
  TemplateFiringDto({
    required this.type,
    required this.firingOrder,
    this.firingDate,
    this.targetCone = '',
    this.targetTemperatureC,
    this.kiln = '',
    this.program = '',
    this.note = '',
  });

  String type;
  DateTime? firingDate;
  String targetCone;
  double? targetTemperatureC;
  String kiln;
  String program;
  String note;
  int firingOrder;

  factory TemplateFiringDto.fromJson(Map<String, dynamic> json) =>
      TemplateFiringDto(
        type: json['type'] as String,
        firingOrder: json['firingOrder'] as int? ?? 1,
        firingDate: DateTime.tryParse(json['firingDate'] as String? ?? ''),
        targetCone: json['targetCone'] as String? ?? '',
        targetTemperatureC: (json['targetTemperatureC'] as num?)?.toDouble(),
        kiln: json['kiln'] as String? ?? '',
        program: json['program'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );

  Map<String, dynamic> toRequestJson() => {
    'type': type,
    'firingDate': firingDate == null
        ? null
        : '${firingDate!.year.toString().padLeft(4, '0')}-'
              '${firingDate!.month.toString().padLeft(2, '0')}-'
              '${firingDate!.day.toString().padLeft(2, '0')}',
    'targetCone': targetCone,
    'targetTemperatureC': targetTemperatureC,
    'kiln': kiln,
    'program': program,
    'note': note,
    'firingOrder': firingOrder,
  };
}

class ProjectTemplatePageDto {
  const ProjectTemplatePageDto({required this.items, this.nextCursor});
  final List<ProjectTemplateDto> items;
  final String? nextCursor;

  factory ProjectTemplatePageDto.fromJson(Map<String, dynamic> json) =>
      ProjectTemplatePageDto(
        items: (json['items'] as List)
            .map((value) => ProjectTemplateDto.fromJson(value))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );
}

class TemplateBatchPreviewDto {
  const TemplateBatchPreviewDto({
    required this.templateVersion,
    required this.titles,
  });
  final int templateVersion;
  final List<String> titles;

  factory TemplateBatchPreviewDto.fromJson(Map<String, dynamic> json) =>
      TemplateBatchPreviewDto(
        templateVersion: (json['templateVersion'] as num).toInt(),
        titles: (json['titles'] as List).cast<String>(),
      );
}
