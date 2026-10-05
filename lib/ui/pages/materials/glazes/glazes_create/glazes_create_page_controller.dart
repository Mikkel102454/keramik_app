import 'package:clay_dock/repositories/glaze_repository.dart';
import 'package:clay_dock/objects/glaze_dto.dart';
import 'package:flutter/material.dart';

class GlazesCreatePageController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String title = '';

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {} catch (e) {
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

  Future<void> save(int? id) async {
    if (id == null) {
      await create();
    } else {
      await GlazeRepository.updateGlaze(GlazeDto(id: id, title: title.trim()));
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}
