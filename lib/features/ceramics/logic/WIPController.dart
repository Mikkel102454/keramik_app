import 'package:flutter/material.dart';
import 'package:kemik_app/classes/stage_dto.dart';

import '../../../classes/ceramic_dto.dart';
import '../../../network/ceramic.dart';

class WIPController extends ChangeNotifier{
  List<CeramicDto> _ceramics = [];
  List<StageDto> _stages = [];

  bool _isLoading = false;
  String? _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stages = await getStages();
      _stages.sort((a, b) => a.id.compareTo(b.id));
      _ceramics = await getCeramics();
      notifyListeners();
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