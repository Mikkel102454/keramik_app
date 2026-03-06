import 'package:flutter/material.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';

class CeramicSelectPageController extends ChangeNotifier{
  List<CeramicDto> _ceramics = [];
  List<StageDto> _stages = [];

  bool _isLoading = false;
  String? _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stages = await CeramicRepository.getStages();
      _stages.sort((a, b) => a.id.compareTo(b.id));
      _ceramics = await CeramicRepository.getCeramics();
    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  bool get isLoading => _isLoading;

  List<CeramicDto> get ceramics => _ceramics;
  List<StageDto> get stages => _stages;

  String? get error => _error;
}