import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'package:flutter/material.dart';

class GlazesPageController extends ChangeNotifier{
  bool _isLoading = false;
  String? _error;
  List<GlazeDto> glazes = [];

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      glazes = await GlazeRepository.getGlazes();
      glazes.sort((a, b) => a.id.compareTo(b.id));
    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}
