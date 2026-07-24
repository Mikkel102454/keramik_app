import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';

enum CeramicJournalSort { recentlyUpdated, title, rating, stage, created }

class CeramicJournalQuery {
  const CeramicJournalQuery({
    this.search = '',
    this.stageIds = const {},
    this.clayIds = const {},
    this.glazeIds = const {},
    this.tags = const {},
    this.minimumRating = 0,
    this.sort = CeramicJournalSort.recentlyUpdated,
    this.descending = true,
  });

  final String search;
  final Set<int> stageIds;
  final Set<int> clayIds;
  final Set<int> glazeIds;
  final Set<String> tags;
  final int minimumRating;
  final CeramicJournalSort sort;
  final bool descending;

  bool get hasFilters =>
      stageIds.isNotEmpty ||
      clayIds.isNotEmpty ||
      glazeIds.isNotEmpty ||
      tags.isNotEmpty ||
      minimumRating > 0;

  int get activeFilterCount =>
      stageIds.length +
      clayIds.length +
      glazeIds.length +
      tags.length +
      (minimumRating > 0 ? 1 : 0);

  List<CeramicDto> apply(
    List<CeramicDto> ceramics,
    List<ClayDto> clays,
    List<GlazeDto> glazes,
  ) {
    final clayNames = {for (final clay in clays) clay.id: _normalize(clay.title)};
    final glazeNames = {for (final glaze in glazes) glaze.id: _normalize(glaze.title)};
    final term = _normalize(search);

    final result = ceramics.where((ceramic) {
      if (stageIds.isNotEmpty && !stageIds.contains(ceramic.stageId)) return false;
      if (clayIds.isNotEmpty && !clayIds.contains(ceramic.clayTypeId)) return false;
      if (glazeIds.isNotEmpty &&
          !ceramic.glazes.any((entry) => glazeIds.contains(entry.glazeId))) {
        return false;
      }
      if (minimumRating > 0 && ceramic.rating < minimumRating) return false;
      if (tags.isNotEmpty &&
          !ceramic.tags.any((tag) => tags.contains(_normalize(tag.tag)))) {
        return false;
      }
      if (term.isEmpty) return true;

      final searchable = <String>[
        ceramic.title,
        ceramic.note,
        ceramic.outcomeNote,
        clayNames[ceramic.clayTypeId] ?? '',
        ...ceramic.tags.map((tag) => tag.tag),
        ...ceramic.glazes.map((entry) => glazeNames[entry.glazeId] ?? ''),
        ...ceramic.glazes.map((entry) => entry.note),
      ].map(_normalize);
      return searchable.any((value) => value.contains(term));
    }).toList();

    result.sort((left, right) {
      final comparison = switch (sort) {
        CeramicJournalSort.recentlyUpdated => _date(left.updatedAt).compareTo(_date(right.updatedAt)),
        CeramicJournalSort.title => left.title.toLowerCase().compareTo(right.title.toLowerCase()),
        CeramicJournalSort.rating => left.rating.compareTo(right.rating),
        CeramicJournalSort.stage => left.stageId.compareTo(right.stageId),
        CeramicJournalSort.created => _date(left.createdAt).compareTo(_date(right.createdAt)),
      };
      final directed = descending ? -comparison : comparison;
      return directed != 0 ? directed : left.id.compareTo(right.id);
    });
    return result;
  }

  CeramicJournalQuery copyWith({
    String? search,
    Set<int>? stageIds,
    Set<int>? clayIds,
    Set<int>? glazeIds,
    Set<String>? tags,
    int? minimumRating,
    CeramicJournalSort? sort,
    bool? descending,
  }) {
    return CeramicJournalQuery(
      search: search ?? this.search,
      stageIds: stageIds ?? this.stageIds,
      clayIds: clayIds ?? this.clayIds,
      glazeIds: glazeIds ?? this.glazeIds,
      tags: tags ?? this.tags,
      minimumRating: minimumRating ?? this.minimumRating,
      sort: sort ?? this.sort,
      descending: descending ?? this.descending,
    );
  }

  CeramicJournalQuery clearFilters() => copyWith(
    stageIds: const {},
    clayIds: const {},
    glazeIds: const {},
    tags: const {},
    minimumRating: 0,
  );

  static String _normalize(String value) => value.trim().toLowerCase();
  static DateTime _date(DateTime? value) =>
      value ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
