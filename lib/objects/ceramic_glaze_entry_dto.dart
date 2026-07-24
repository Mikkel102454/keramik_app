class CeramicGlazeEntryDto {
  final int id;
  final int glazeId;
  final int ceramicId;
  String note;
  int layerOrder;
  int coatCount;

  CeramicGlazeEntryDto({
    required this.id,
    required this.glazeId,
    required this.ceramicId,
    required this.note,
    this.layerOrder = 1,
    this.coatCount = 1,
  });

  factory CeramicGlazeEntryDto.fromJson(Map<String, dynamic> json) {
    return CeramicGlazeEntryDto(
      id: json['id'],
      glazeId: json['glazeId'],
      ceramicId: json['ceramicId'],
      note: json['note'],
      layerOrder: json['layerOrder'] as int? ?? 1,
      coatCount: json['coatCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'glazeId': glazeId,
      'ceramicId': ceramicId,
      'note': note,
      'layerOrder': layerOrder,
      'coatCount': coatCount,
    };
  }
}
