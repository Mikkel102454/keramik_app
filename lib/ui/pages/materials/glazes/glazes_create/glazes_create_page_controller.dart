import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'package:flutter/material.dart';

class GlazesCreatePageController extends ChangeNotifier{
  bool _isLoading = false;
  String? _error;
  String title = '';

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setTitle(String value) {
    title = value;
  }

  Future<void> create() async {
    await GlazeRepository.createGlaze(title.trim());
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}
