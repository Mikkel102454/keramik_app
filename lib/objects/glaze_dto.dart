class GlazeDto {
  final int id;
  final String title;

  GlazeDto({
    required this.id,
    required this.title,
  });

  factory GlazeDto.fromJson(Map<String, dynamic> json) {
    return GlazeDto(
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