import 'package:clay_dock/objects/clay_dto.dart';
import 'package:clay_dock/repositories/clay_repository.dart';
import 'package:flutter/material.dart';

class ClaysPageController extends ChangeNotifier{
  bool _isLoading = false;
  String? _error;

  List<ClayDto> clayTypes = [];

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      clayTypes = await ClayRepository.getClayTypes();
      clayTypes.sort((a, b) => a.id.compareTo(b.id));
    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}