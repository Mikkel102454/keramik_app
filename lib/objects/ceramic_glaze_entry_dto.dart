class CeramicGlazeEntryDto {
  final int id;
  final int glazeId;
  final int ceramicId;
  String note;

  CeramicGlazeEntryDto({
    required this.id,
    required this.glazeId,
    required this.ceramicId,
    required this.note,
  });

  factory CeramicGlazeEntryDto.fromJson(Map<String, dynamic> json) {
    return CeramicGlazeEntryDto(
      id: json['id'],
      glazeId: json['glazeId'],
      ceramicId: json['ceramicId'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'glazeId': glazeId,
      'ceramicId': ceramicId,
      'note': note,
    };
  }
}