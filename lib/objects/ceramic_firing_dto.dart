class CeramicFiringDto {
  CeramicFiringDto({
    required this.id,
    required this.ceramicId,
    required this.status,
    required this.type,
    this.firingDate,
    this.targetCone = '',
    this.targetTemperatureC,
    this.observedCone = '',
    this.peakTemperatureC,
    this.kiln = '',
    this.program = '',
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int ceramicId;
  String status;
  String type;
  DateTime? firingDate;
  String targetCone;
  double? targetTemperatureC;
  String observedCone;
  double? peakTemperatureC;
  String kiln;
  String program;
  String note;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory CeramicFiringDto.fromJson(Map<String, dynamic> json) {
    return CeramicFiringDto(
      id: json['id'] as int,
      ceramicId: json['ceramicId'] as int,
      status: json['status'] as String,
      type: json['type'] as String,
      firingDate: DateTime.tryParse(json['firingDate'] as String? ?? ''),
      targetCone: json['targetCone'] as String? ?? '',
      targetTemperatureC: (json['targetTemperatureC'] as num?)?.toDouble(),
      observedCone: json['observedCone'] as String? ?? '',
      peakTemperatureC: (json['peakTemperatureC'] as num?)?.toDouble(),
      kiln: json['kiln'] as String? ?? '',
      program: json['program'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toRequestJson() => {
    'status': status,
    'type': type,
    'firingDate': firingDate == null
        ? null
        : '${firingDate!.year.toString().padLeft(4, '0')}-'
              '${firingDate!.month.toString().padLeft(2, '0')}-'
              '${firingDate!.day.toString().padLeft(2, '0')}',
    'targetCone': targetCone,
    'targetTemperatureC': targetTemperatureC,
    'observedCone': observedCone,
    'peakTemperatureC': peakTemperatureC,
    'kiln': kiln,
    'program': program,
    'note': note,
  };
}
