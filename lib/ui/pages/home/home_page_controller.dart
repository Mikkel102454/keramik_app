import 'package:ceramic_app/repositories/stage_repository.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'ceramic_journal_query.dart';

class HomePageController extends ChangeNotifier{
  bool _disposed = false;
  List<CeramicDto> _ceramics = [];
  List<StageDto> _stages = [];
  List<ClayDto> _clays = [];
  List<GlazeDto> _glazes = [];
  CeramicJournalQuery _query = const CeramicJournalQuery();

  bool _isLoading = false;
  String? _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _notify();

    try {
      final results = await Future.wait<dynamic>([
        StageRepository.getStages(),
        CeramicRepository.getCeramics(),
        ClayRepository.getClayTypes(),
        GlazeRepository.getGlazes(),
      ]);
      if (_disposed) return;
      _stages = results[0] as List<StageDto>;
      _stages.sort((a, b) => a.id.compareTo(b.id));
      _ceramics = results[1] as List<CeramicDto>;
      _clays = results[2] as List<ClayDto>;
      _glazes = results[3] as List<GlazeDto>;
    } catch (e){
      _error = 'We could not load your ceramic journal.';
    }

    _isLoading = false;
    _notify();
  }

  bool get isLoading => _isLoading;

  List<CeramicDto> get ceramics => _ceramics;
  List<StageDto> get stages => _stages;
  List<ClayDto> get clays => _clays;
  List<GlazeDto> get glazes => _glazes;
  CeramicJournalQuery get query => _query;
  List<CeramicDto> get visibleCeramics => _query.apply(_ceramics, _clays, _glazes);
  List<String> get availableTags => {
    for (final ceramic in _ceramics)
      for (final tag in ceramic.tags) tag.tag.trim(),
  }.where((tag) => tag.isNotEmpty).toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  void updateQuery(CeramicJournalQuery value) {
    _query = value;
    _notify();
  }

  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
