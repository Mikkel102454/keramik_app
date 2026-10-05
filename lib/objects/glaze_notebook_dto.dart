import 'dart:convert';
import 'package:clay_dock/objects/ceramic_firing_dto.dart';
import 'package:clay_dock/objects/ceramic_glaze_entry_dto.dart';
import 'package:clay_dock/objects/image_dto.dart';

class NotebookLayerDto {
  NotebookLayerDto({
    this.id,
    this.glazeId,
    required this.glazeTitle,
    this.coatCount = 1,
    this.note = '',
  });
  int? id;
  int? glazeId;
  String glazeTitle;
  int coatCount;
  String note;
  factory NotebookLayerDto.fromJson(Map<String, dynamic> j) => NotebookLayerDto(
    id: j['id'],
    glazeId: j['glazeId'],
    glazeTitle: j['glazeTitle'] ?? '',
    coatCount: j['coatCount'] ?? 1,
    note: j['note'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'glazeId': glazeId,
    'glazeTitle': glazeTitle,
    'coatCount': coatCount,
    'note': note,
  };
  CeramicGlazeEntryDto entry(int localId, int order) => CeramicGlazeEntryDto(
    id: localId,
    glazeId: glazeId ?? 0,
    ceramicId: 0,
    note: note,
    layerOrder: order,
    coatCount: coatCount,
  );
}

class NotebookFiringDto {
  NotebookFiringDto({this.id, required this.firing, this.atmosphere});
  int? id;
  CeramicFiringDto firing;
  String? atmosphere;
  factory NotebookFiringDto.fromJson(Map<String, dynamic> j) =>
      NotebookFiringDto(
        id: j['id'],
        atmosphere: j['atmosphere'],
        firing: CeramicFiringDto.fromJson({
          ...j,
          'id': j['id'] ?? 0,
          'ceramicId': 0,
        }),
      );
  Map<String, dynamic> toJson() => {
    ...firing.toRequestJson(),
    'id': id,
    'atmosphere': atmosphere,
  };
}

class GlazeNotebookDto {
  GlazeNotebookDto({
    this.id = 0,
    this.version = 0,
    required this.name,
    this.notes = '',
    this.clayId,
    this.clayTitle,
    this.resultNotes = '',
    required this.layers,
    required this.firings,
    this.sourceCombinationId,
    this.sourceName,
    this.sourceVersion,
    this.sourceSnapshot,
    this.images = const [],
  });
  final int id;
  final int version;
  String name;
  String notes;
  int? clayId;
  String? clayTitle;
  String resultNotes;
  List<NotebookLayerDto> layers;
  List<NotebookFiringDto> firings;
  int? sourceCombinationId;
  String? sourceName;
  int? sourceVersion;
  String? sourceSnapshot;
  List<ImageDto> images;
  factory GlazeNotebookDto.fromJson(Map<String, dynamic> j) => GlazeNotebookDto(
    id: j['id'],
    version: j['version'],
    name: j['name'],
    notes: j['notes'] ?? '',
    clayId: j['clayId'],
    clayTitle: j['clayTitle'],
    resultNotes: j['resultNotes'] ?? '',
    layers: (j['layers'] as List)
        .map((l) => NotebookLayerDto.fromJson(l))
        .toList(),
    firings: (j['firings'] as List)
        .map((f) => NotebookFiringDto.fromJson(f))
        .toList(),
    sourceCombinationId: j['sourceCombinationId'],
    sourceName: j['sourceName'],
    sourceVersion: j['sourceVersion'],
    sourceSnapshot: j['sourceSnapshot'],
    images: (j['images'] as List? ?? [])
        .map((i) => ImageDto.fromJson(i))
        .toList(),
  );
  Map<String, dynamic> toRequestJson() => {
    'name': name,
    'notes': notes,
    'clayId': clayId,
    'resultNotes': resultNotes,
    'expectedVersion': version,
    'sourceCombinationId': sourceCombinationId,
    'expectedCombinationVersion': sourceVersion,
    'layers': layers.map((l) => l.toJson()).toList(),
    'firings': firings.map((f) => f.toJson()).toList(),
  };
  GlazeNotebookDto tileDraft() => GlazeNotebookDto(
    name: name,
    notes: notes,
    clayId: clayId,
    clayTitle: clayTitle,
    sourceCombinationId: id,
    sourceName: name,
    sourceVersion: version,
    layers: layers
        .map((l) => NotebookLayerDto.fromJson(l.toJson()..['id'] = null))
        .toList(),
    firings: firings
        .map((f) => NotebookFiringDto.fromJson(f.toJson()..['id'] = null))
        .toList(),
  );
  GlazeNotebookDto? get originalRecipe => sourceSnapshot == null
      ? null
      : GlazeNotebookDto.fromJson(jsonDecode(sourceSnapshot!));
}

class NotebookPageDto {
  NotebookPageDto(this.items, this.nextCursor);
  final List<GlazeNotebookDto> items;
  final String? nextCursor;
  factory NotebookPageDto.fromJson(Map<String, dynamic> j) => NotebookPageDto(
    (j['items'] as List).map((n) => GlazeNotebookDto.fromJson(n)).toList(),
    j['nextCursor'],
  );
}
