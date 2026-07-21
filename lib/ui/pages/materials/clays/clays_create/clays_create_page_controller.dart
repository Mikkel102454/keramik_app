import 'dart:io';

import 'package:ceramic_app/extensions/extensions.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:ceramic_app/utils/file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ClaysCreatePageController extends ChangeNotifier{
  bool _isLoading = false;
  String? _error;

  String title = '';
  List<XFile> images = [];
  String supplier = '';
  String notes = '';

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

  void setSupplier(String value) {
    supplier = value;
  }

  void setNotes(String value) {
    notes = value;
  }

  Future<bool> uploadImage(File file) async {
    List<XFile> oldImages = images.copy();
    try {
      final XFile compressed = await compressFile(file);
      images.add(compressed);
      notifyListeners();
      return true;

    } catch (e) {
      images = oldImages;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteImage(int imageId) async {
    List<XFile> oldImages = images.copy();
    try {
      final removed = images.removeAt(imageId);
      final file = File(removed.path);
      if (await file.exists()) await file.delete();
      notifyListeners();
      return true;

    } catch (e) {
      images = oldImages;
      notifyListeners();
      return false;
    }
  }

  Future<void> create() async{
    ClayDto clayDto = ClayDto(
      title: title,
      supplier: supplier,
      note: notes,
      images: [],
      id: 0,
    );
    await ClayRepository.createClay(clay: clayDto, images: images);
    await cleanupImages();
  }

  Future<void> cleanupImages() async {
    final drafts = List<XFile>.from(images);
    images.clear();
    for (final draft in drafts) {
      final file = File(draft.path);
      if (await file.exists()) await file.delete();
    }
  }

  @override
  void dispose() {
    cleanupImages();
    super.dispose();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}
