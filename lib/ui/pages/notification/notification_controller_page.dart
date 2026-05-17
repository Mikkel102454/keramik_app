import 'package:ceramic_app/repositories/stage_repository.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';

class NotificationControllerPage extends ChangeNotifier{
  bool _isLoading = false;
  String? _error;

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

  bool get isLoading => _isLoading;
  String? get error => _error;
}