class StageDto {
  final int id;
  final String title;

  StageDto({
    required this.id,
    required this.title,
  });

  factory StageDto.fromJson(Map<String, dynamic> json) {
    return StageDto(
      id: json['id'],
      title: json['title'],
    );
  }
}