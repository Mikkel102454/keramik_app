class PublicCeramicCardDto {
  const PublicCeramicCardDto({
    required this.title,
    required this.stage,
    required this.rating,
    this.imageUrl,
    this.clayTitle,
  });

  final String? imageUrl;
  final String title;
  final String stage;
  final String? clayTitle;
  final int rating;

  factory PublicCeramicCardDto.fromJson(Map<String, dynamic> json) {
    return PublicCeramicCardDto(
      imageUrl: json['imageUrl'] as String?,
      title: json['title'] as String,
      stage: json['stage'] as String,
      clayTitle: json['clayTitle'] as String?,
      rating: (json['rating'] as num).toInt(),
    );
  }
}
