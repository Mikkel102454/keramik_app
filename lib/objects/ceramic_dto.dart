/* ---------- Category Model ---------- */
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';

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

  CeramicDto({
    required this.id,
    required this.stageId,
    required this.title,
    required this.clayTypeId,
    required this.rating,
    required this.weight,
    required this.note,
    required this.glazes,
    required this.tags
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
    };
  }
}