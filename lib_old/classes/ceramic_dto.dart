/* ---------- Category Model ---------- */
class CeramicDto {
  final int id;
  final int stage;
  final String title;
  final String type;
  final double rate;
  final double weight;
  final String note;

  CeramicDto({
    required this.id,
    required this.stage,
    required this.title,
    required this.type,
    required this.rate,
    required this.weight,
    required this.note,
  });

  factory CeramicDto.fromJson(Map<String, dynamic> json) {
    return CeramicDto(
      id: json['id'],
      stage: json['stage'],
      title: json['title'],
      type: json['type'],
      rate: json['rate'],
      weight: json['weight'],
      note: json['note'],
    );
  }
}