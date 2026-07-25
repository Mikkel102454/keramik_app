import 'package:ceramic_app/objects/ceramic_firing_dto.dart';
import 'package:ceramic_app/objects/ceramic_stage_history_dto.dart';
import 'package:ceramic_app/objects/image_dto.dart';

class SharedCeramicGlazeDto {
  const SharedCeramicGlazeDto({
    required this.title,
    required this.note,
    required this.layerOrder,
    required this.coatCount,
  });

  final String title;
  final String note;
  final int layerOrder;
  final int coatCount;

  factory SharedCeramicGlazeDto.fromJson(Map<String, dynamic> json) {
    return SharedCeramicGlazeDto(
      title: json['title'] as String,
      note: json['note'] as String? ?? '',
      layerOrder: (json['layerOrder'] as num?)?.toInt() ?? 1,
      coatCount: (json['coatCount'] as num?)?.toInt() ?? 1,
    );
  }
}

class SharedCeramicDetailDto {
  const SharedCeramicDetailDto({
    required this.available,
    required this.tags,
    required this.glazes,
    required this.firings,
    required this.stageHistory,
    required this.images,
    required this.imageCount,
    this.title,
    this.stage,
    this.clayTitle,
    this.rating,
    this.weight,
    this.heightCm,
    this.widthCm,
    this.depthCm,
    this.diameterCm,
    this.note,
    this.outcomeNote,
    this.createdAt,
    this.updatedAt,
  });

  final bool available;
  final String? title;
  final String? stage;
  final String? clayTitle;
  final int? rating;
  final double? weight;
  final double? heightCm;
  final double? widthCm;
  final double? depthCm;
  final double? diameterCm;
  final String? note;
  final String? outcomeNote;
  final List<String> tags;
  final List<SharedCeramicGlazeDto> glazes;
  final List<CeramicFiringDto> firings;
  final List<CeramicStageHistoryDto> stageHistory;
  final List<ImageDto> images;
  final int imageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SharedCeramicDetailDto.fromJson(Map<String, dynamic> json) {
    return SharedCeramicDetailDto(
      available: json['available'] as bool? ?? false,
      title: json['title'] as String?,
      stage: json['stage'] as String?,
      clayTitle: json['clayTitle'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      widthCm: (json['widthCm'] as num?)?.toDouble(),
      depthCm: (json['depthCm'] as num?)?.toDouble(),
      diameterCm: (json['diameterCm'] as num?)?.toDouble(),
      note: json['note'] as String?,
      outcomeNote: json['outcomeNote'] as String?,
      tags: (json['tags'] as List? ?? const []).cast<String>(),
      glazes: (json['glazes'] as List? ?? const [])
          .map((item) => SharedCeramicGlazeDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      firings: (json['firings'] as List? ?? const [])
          .map((item) => CeramicFiringDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      stageHistory: (json['stageHistory'] as List? ?? const [])
          .map((item) => CeramicStageHistoryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List? ?? const [])
          .map((item) => ImageDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal(),
    );
  }
}
