import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_journal_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clays = [
    ClayDto(title: 'Porcelain', note: '', id: 10, supplier: '', images: []),
    ClayDto(title: 'Stoneware', note: '', id: 11, supplier: '', images: []),
  ];
  final glazes = [
    GlazeDto(id: 20, title: 'Ocean Blue'),
    GlazeDto(id: 21, title: 'Satin White'),
  ];
  final ceramics = [
    _ceramic(
      id: 1,
      title: 'Blue bowl',
      note: 'Wheel thrown',
      stageId: 2,
      clayId: 10,
      rating: 5,
      glazeId: 20,
      tag: 'gift',
      updatedAt: DateTime.utc(2026, 7, 20),
    ),
    _ceramic(
      id: 2,
      title: 'Tall vase',
      note: 'Coiled form',
      stageId: 6,
      clayId: 11,
      rating: 3,
      glazeId: 21,
      tag: 'studio',
      updatedAt: DateTime.utc(2026, 7, 22),
    ),
  ];

  test('search covers ceramic text, tags, clay, and glaze names', () {
    for (final term in ['wheel', 'gift', 'porcelain', 'ocean']) {
      final result = CeramicJournalQuery(search: term).apply(ceramics, clays, glazes);
      expect(result.map((item) => item.id), [1], reason: term);
    }
  });

  test('filters OR within a category and AND across categories', () {
    const query = CeramicJournalQuery(
      stageIds: {2, 6},
      clayIds: {10},
      glazeIds: {20, 21},
      tags: {'gift', 'studio'},
      minimumRating: 4,
    );
    expect(query.apply(ceramics, clays, glazes).map((item) => item.id), [1]);
  });

  test('recently updated defaults to newest first', () {
    expect(
      const CeramicJournalQuery().apply(ceramics, clays, glazes).map((item) => item.id),
      [2, 1],
    );
  });
}

CeramicDto _ceramic({
  required int id,
  required String title,
  required String note,
  required int stageId,
  required int clayId,
  required int rating,
  required int glazeId,
  required String tag,
  required DateTime updatedAt,
}) {
  return CeramicDto(
    id: id,
    stageId: stageId,
    title: title,
    clayTypeId: clayId,
    rating: rating,
    weight: 0,
    note: note,
    glazes: [
      CeramicGlazeEntryDto(
        id: id,
        glazeId: glazeId,
        ceramicId: id,
        note: '',
      ),
    ],
    tags: [CeramicTagDto(id: id, ceramicId: id, tag: tag)],
    images: const [],
    updatedAt: updatedAt,
  );
}
