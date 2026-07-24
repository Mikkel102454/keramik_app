/* ---------- Category Model ---------- */
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/objects/image_dto.dart';

class CeramicDto {
  int id;
  String title;
  int stageId;
  int clayTypeId;
  int rating;
  double weight;
  String note;
  List<CeramicGlazeEntryDto> glazes;
  List<CeramicTagDto> tags;
  List<ImageDto> images;
  double? heightCm;
  double? widthCm;
  double? depthCm;
  double? diameterCm;
  String outcomeNote;
  DateTime? createdAt;
  DateTime? updatedAt;

  CeramicDto({
    required this.id,
    required this.stageId,
    required this.title,
    required this.clayTypeId,
    required this.rating,
    required this.weight,
    required this.note,
    required this.glazes,
    required this.tags,
    required this.images,
    this.heightCm,
    this.widthCm,
    this.depthCm,
    this.diameterCm,
    this.outcomeNote = '',
    this.createdAt,
    this.updatedAt,
  });

  factory CeramicDto.fromJson(Map<String, dynamic> json) {
    return CeramicDto(
      id: json['id'],
      stageId: json['stageId'],
      title: json['title'],
      clayTypeId: json['clayTypeId'],
      rating: json['rating'],
      weight: json['weight'],
      note: json['note'],
      glazes: (json['glazes'] as List).map((e) => CeramicGlazeEntryDto.fromJson(e)).toList(),
      tags: (json['tags'] as List).map((e) => CeramicTagDto.fromJson(e)).toList(),
      images: (json['images'] as List).map((e) => ImageDto.fromJson(e)).toList(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      widthCm: (json['widthCm'] as num?)?.toDouble(),
      depthCm: (json['depthCm'] as num?)?.toDouble(),
      diameterCm: (json['diameterCm'] as num?)?.toDouble(),
      outcomeNote: json['outcomeNote'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stageId': stageId,
      'title': title,
      'clayTypeId': clayTypeId,
      'rating': rating,
      'weight': weight,
      'note': note,
      'glazes': glazes.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'images': images.map((e) => e.toJson()).toList(),
      'heightCm': heightCm,
      'widthCm': widthCm,
      'depthCm': depthCm,
      'diameterCm': diameterCm,
      'outcomeNote': outcomeNote,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
