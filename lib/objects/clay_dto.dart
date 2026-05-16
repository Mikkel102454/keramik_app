import 'package:ceramic_app/objects/image_dto.dart';

class ClayDto {
  String title;
  String supplier;
  String note;
  int id;
  List<ImageDto> images;

  ClayDto({
    required this.title,
    required this.note,
    required this.id,
    required this.supplier,
    required this.images,
  });

  factory ClayDto.fromJson(Map<String, dynamic> json) {
    return ClayDto(
      id: json['id'],
      title: json['title'],
      note: json['note'],
      supplier: json['supplier'],
      images: (json['images'] as List).map((e) => ImageDto.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'supplier': supplier,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}