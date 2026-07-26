class PublicationCreatorDto {
  const PublicationCreatorDto({
    required this.userId,
    required this.username,
    required this.avatarInitials,
    required this.avatarColor,
    this.avatarUrl,
  });
  final String userId;
  final String username;
  final String? avatarUrl;
  final String avatarInitials;
  final String avatarColor;

  factory PublicationCreatorDto.fromJson(Map<String, dynamic> json) =>
      PublicationCreatorDto(
        userId: json['userId'] as String,
        username: json['username'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        avatarInitials: json['avatarInitials'] as String,
        avatarColor: json['avatarColor'] as String,
      );
}

class PublicationImageDto {
  const PublicationImageDto({required this.id, required this.uri});
  final int id;
  final String uri;
  factory PublicationImageDto.fromJson(Map<String, dynamic> json) =>
      PublicationImageDto(id: (json['id'] as num).toInt(), uri: json['uri'] as String);
}

class PublicationCardDto {
  const PublicationCardDto({
    required this.publicationId,
    required this.creator,
    required this.title,
    required this.likeCount,
    required this.likedByMe,
    required this.ownedByMe,
    required this.publishedAt,
    this.primaryImage,
    this.clay,
  });
  final String publicationId;
  final PublicationCreatorDto creator;
  final PublicationImageDto? primaryImage;
  final String title;
  final String? clay;
  final int likeCount;
  final bool likedByMe;
  final bool ownedByMe;
  final DateTime publishedAt;

  factory PublicationCardDto.fromJson(Map<String, dynamic> json) =>
      PublicationCardDto(
        publicationId: json['publicationId'] as String,
        creator: PublicationCreatorDto.fromJson(json['creator'] as Map<String, dynamic>),
        primaryImage: json['primaryImage'] == null
            ? null
            : PublicationImageDto.fromJson(json['primaryImage'] as Map<String, dynamic>),
        title: json['title'] as String,
        clay: json['clay'] as String?,
        likeCount: (json['likeCount'] as num).toInt(),
        likedByMe: json['likedByMe'] as bool? ?? false,
        ownedByMe: json['ownedByMe'] as bool? ?? false,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
      );

  PublicationCardDto copyWith({int? likeCount, bool? likedByMe}) =>
      PublicationCardDto(
        publicationId: publicationId,
        creator: creator,
        title: title,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
        ownedByMe: ownedByMe,
        publishedAt: publishedAt,
        primaryImage: primaryImage,
        clay: clay,
      );
}

class DiscoverPageDto {
  const DiscoverPageDto(this.items, this.nextCursor);
  final List<PublicationCardDto> items;
  final String? nextCursor;
  factory DiscoverPageDto.fromJson(Map<String, dynamic> json) => DiscoverPageDto(
        (json['items'] as List)
            .map((item) => PublicationCardDto.fromJson(item as Map<String, dynamic>))
            .toList(),
        json['nextCursor'] as String?,
      );
}

class PublicationStatusDto {
  const PublicationStatusDto({
    this.publicationId,
    this.state,
    required this.current,
    required this.eligible,
    required this.currentAudience,
    required this.replayed,
    required this.changed,
  });
  final String? publicationId;
  final String? state;
  final bool current;
  final bool eligible;
  final String currentAudience;
  final bool replayed;
  final bool changed;

  factory PublicationStatusDto.fromJson(Map<String, dynamic> json) =>
      PublicationStatusDto(
        publicationId: json['publicationId'] as String?,
        state: json['state'] as String?,
        current: json['current'] as bool? ?? false,
        eligible: json['eligible'] as bool? ?? false,
        currentAudience: json['currentAudience'] as String? ?? 'FRIENDS',
        replayed: json['replayed'] as bool? ?? false,
        changed: json['changed'] as bool? ?? false,
      );
}

class PublicationDetailDto {
  const PublicationDetailDto({
    required this.publicationId,
    required this.creator,
    required this.images,
    required this.totalImageCount,
    required this.title,
    required this.tags,
    required this.rating,
    required this.publishedAt,
    required this.likeCount,
    required this.likedByMe,
    required this.currentAudience,
    this.clay,
    this.heightCm,
    this.widthCm,
    this.depthCm,
    this.diameterCm,
    this.outcome,
  });

  final String publicationId;
  final PublicationCreatorDto creator;
  final List<PublicationImageDto> images;
  final int totalImageCount;
  final String title;
  final String? clay;
  final List<String> tags;
  final int rating;
  final double? heightCm;
  final double? widthCm;
  final double? depthCm;
  final double? diameterCm;
  final String? outcome;
  final DateTime publishedAt;
  final int likeCount;
  final bool likedByMe;
  final String currentAudience;

  factory PublicationDetailDto.fromJson(Map<String, dynamic> json) =>
      PublicationDetailDto(
        publicationId: json['publicationId'] as String,
        creator: PublicationCreatorDto.fromJson(
          json['creator'] as Map<String, dynamic>,
        ),
        images: (json['images'] as List)
            .map((item) => PublicationImageDto.fromJson(
                  item as Map<String, dynamic>,
                ))
            .toList(),
        totalImageCount: (json['totalImageCount'] as num).toInt(),
        title: json['title'] as String,
        clay: json['clay'] as String?,
        tags: (json['tags'] as List).cast<String>(),
        rating: (json['rating'] as num).toInt(),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        widthCm: (json['widthCm'] as num?)?.toDouble(),
        depthCm: (json['depthCm'] as num?)?.toDouble(),
        diameterCm: (json['diameterCm'] as num?)?.toDouble(),
        outcome: json['outcome'] as String?,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        likeCount: (json['likeCount'] as num).toInt(),
        likedByMe: json['likedByMe'] as bool? ?? false,
        currentAudience: json['currentAudience'] as String,
      );
}
