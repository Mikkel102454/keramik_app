class CeramicGlazeNoteDto {
  final int id;
  final int ceramicId;
  final String note;

  CeramicGlazeNoteDto({
    required this.id,
    required this.ceramicId,
    required this.note,
  });

  factory CeramicGlazeNoteDto.fromJson(Map<String, dynamic> json) {
    return CeramicGlazeNoteDto(
      id: json['id'],
      ceramicId: json['ceramicId'],
      note: json['note'],
    );
  }
}