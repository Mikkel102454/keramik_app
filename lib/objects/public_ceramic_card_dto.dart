class PublicCeramicCardDto {
  const PublicCeramicCardDto({
    required this.title,
    required this.stage,
    required this.rating,
    this.imageUrl,
    this.clayTitle,
    this.publicationId,
    this.likeCount = 0,
  });

  final String? imageUrl;
  final String title;
  final String stage;
  final String? clayTitle;
  final int rating;
  final String? publicationId;
  final int likeCount;

  factory PublicCeramicCardDto.fromJson(Map<String, dynamic> json) {
    return PublicCeramicCardDto(
      imageUrl: json['imageUrl'] as String?,
      title: json['title'] as String,
      stage: json['stage'] as String,
      clayTitle: json['clayTitle'] as String?,
      rating: (json['rating'] as num).toInt(),
      publicationId: json['publicationId'] as String?,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    );
  }
}
