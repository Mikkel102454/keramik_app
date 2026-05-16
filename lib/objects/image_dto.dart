class ImageDto{
  int id;
  String uri;
  int objectId;

  ImageDto({
    required this.id,
    required this.uri,
    required this.objectId,
  });

  factory ImageDto.fromJson(Map<String, dynamic> json) {
    return ImageDto(
      id: json['id'],
      uri: json['uri'],
      objectId: json['objectId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uri': uri,
      'objectId': objectId,
    };
  }
}