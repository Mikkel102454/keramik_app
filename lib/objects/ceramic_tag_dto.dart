class CeramicTagDto {
  final int id;
  final int ceramicId;
  final String tag;

  CeramicTagDto({
    required this.id,
    required this.ceramicId,
    required this.tag,
  });

  factory CeramicTagDto.fromJson(Map<String, dynamic> json) {
    return CeramicTagDto(
      id: json['id'],
      ceramicId: json['ceramicId'],
      tag: json['tag'],
    );
  }
}