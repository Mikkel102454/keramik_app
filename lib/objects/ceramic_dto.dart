/* ---------- Category Model ---------- */
class CeramicDto {
  int id;
  int stage;
  String title;
  String type;
  int rate;
  double weight;
  String note;

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
      rate: json['rate'].toInt(),
      weight: json['weight'],
      note: json['note'],
    );
  }
}