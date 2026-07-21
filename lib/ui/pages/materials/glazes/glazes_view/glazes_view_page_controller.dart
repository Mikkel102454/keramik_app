import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'package:flutter/material.dart';

class GlazesViewPageController extends ChangeNotifier{
  bool _isLoading = false;
  String? _error;
  late GlazeDto glaze;
  bool hasChanged = false;

  Future<void> load(GlazeDto? initialGlaze) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      glaze = initialGlaze ?? await GlazeRepository.getGlaze(glaze.id);
    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setTitle(String value) async {
    final oldTitle = glaze.title;
    try {
      glaze.title = value.trim();
      notifyListeners();
      await GlazeRepository.updateGlaze(glaze);
      hasChanged = true;
      return true;
    } catch (_) {
      glaze.title = oldTitle;
      notifyListeners();
      return false;
    }
  }

  Future<String?> deleteGlaze() async {
    try {
      await GlazeRepository.deleteGlaze(glaze.id);
      hasChanged = true;
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}
