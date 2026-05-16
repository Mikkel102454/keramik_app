import 'dart:io';

import 'package:ceramic_app/extensions/extensions.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/image_dto.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:flutter/material.dart';

class ClaysViewPageController extends ChangeNotifier{
  bool _isLoading = false;
  String? _error;

  late ClayDto clay;

  bool hasChanged = false;

  Future<void> load(ClayDto? clay) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      clay ??= await ClayRepository.getClay(this.clay.id);
      this.clay = clay;
    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setTitle(String value) async {
    final oldValue = clay.title;
    try {
      clay.title = value;
      notifyListeners();
      await ClayRepository.updateClay(clay: clay);
      hasChanged = true;
      return true;
    } catch (e) {
      clay.title = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setSupplier(String value) async {
    final oldValue = clay.supplier;
    try {
      clay.supplier = value;
      notifyListeners();
      await ClayRepository.updateClay(clay: clay);
      hasChanged = true;
      return true;
    } catch (e) {
      clay.supplier = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setNote(String value) async {
    final oldValue = clay.note;
    try {
      clay.note = value;
      notifyListeners();
      await ClayRepository.updateClay(clay: clay);
      hasChanged = true;
      return true;
    } catch (e) {
      clay.note = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadImage(File file) async {
    List<ImageDto> oldImages = clay.images.copy();
    try {
      final image = await ClayRepository.uploadClayImage(
        id: clay.id,
        file: file,
      );

      clay.images.add(image);
      hasChanged = true;
      notifyListeners();
      return true;

    } catch (e) {
      clay.images = oldImages;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteImage(ImageDto image) async {
    List<ImageDto> oldImages = clay.images.copy();
    try {
      await ClayRepository.deleteClayImage(
        image: image,
      );

      clay.images.removeWhere((e) => e.id == image.id);
      hasChanged = true;
      notifyListeners();
      return true;

    } catch (e) {
      clay.images = oldImages;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClay() async {
    try {
      await ClayRepository.deleteClay(clay.id);
      hasChanged = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}