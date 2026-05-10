class ClayDto {
  final String title;
  final int id;

  ClayDto({
    required this.title,
    required this.id,
  });

  factory ClayDto.fromJson(Map<String, dynamic> json) {
    return ClayDto(
      id: json['id'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}