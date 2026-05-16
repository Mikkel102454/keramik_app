import 'package:flutter/material.dart';

class GlazesCombinationViewPageController extends ChangeNotifier{
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