class CeramicImageDto {
  final int id;
  final int ceramicId;
  String uri;

  CeramicImageDto({
    required this.id,
    required this.ceramicId,
    required this.uri,
  });

  factory CeramicImageDto.fromJson(Map<String, dynamic> json) {
    return CeramicImageDto(
      id: json['id'],
      ceramicId: json['ceramicId'],
      uri: json['uri'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ceramicId': ceramicId,
      'uri': uri,
    };
  }
}