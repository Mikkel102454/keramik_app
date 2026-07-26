import 'dart:io';

import 'package:ceramic_app/extensions/extensions.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/repositories/stage_repository.dart';
import 'package:ceramic_app/utils/file.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/utils/measurement.dart';

class CeramicCreatePageController extends ChangeNotifier{
  List<StageDto> stages = [];

  String title = '';
  int clayTypeId = 0;
  double weight = 0.0;
  List<CeramicGlazeEntryDto> glazes = [];
  List<CeramicTagDto> tags = [];
  List<XFile> images = [];
  String notes = '';
  int rating = 0;
  int stageId = 1;
  double? heightCm;
  double? widthCm;
  double? depthCm;
  double? diameterCm;
  String outcomeNote = '';

  bool _isLoading = false;
  String? _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      stages = await StageRepository.getStages();
      stageId = stages.first.id;
    } catch (e){
      _error = 'We could not prepare the ceramic form.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ================= Setters =================

  void setTitle(String value) {
    title = value;
  }

  void setClayType(int id) {
    clayTypeId = id;
  }

  void setWeight(String value) {
    final displayValue = double.tryParse(value) ?? 0.0;
    weight = Measurement.weightToKilograms(
      displayValue,
      AppSettingsController.instance.measurementSystem,
    );
  }

  Future<bool> updateGlaze(int id, String value, int coatCount) async {
    final glaze = glazes.firstWhere((g) => g.id == id);
    glaze.note = value;
    glaze.coatCount = coatCount;
    notifyListeners();
    return true;
  }

  Future<int> addGlaze(int glazeId) async {
    final newId = glazes.isEmpty
        ? 1
        : glazes.last.id + 1;

    glazes.add(
      CeramicGlazeEntryDto(
        id: newId,
        glazeId: glazeId,
        ceramicId: 0,
        note: "",
        layerOrder: glazes.length + 1,
        coatCount: 1,
      ),
    );

    notifyListeners();
    return newId;
  }

  Future<bool> moveGlaze(int id, int direction) async {
    glazes.sort((a, b) => a.layerOrder.compareTo(b.layerOrder));
    final index = glazes.indexWhere((entry) => entry.id == id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= glazes.length) return false;
    final moved = glazes.removeAt(index);
    glazes.insert(target, moved);
    for (var i = 0; i < glazes.length; i++) {
      glazes[i].layerOrder = i + 1;
    }
    notifyListeners();
    return true;
  }

  Future<void> removeGlaze(int id) async {
    glazes.removeWhere((g) => g.id == id);
    for (var i = 0; i < glazes.length; i++) {
      glazes[i].layerOrder = i + 1;
    }
    notifyListeners();
  }

  Future<void> updateTag(int id, String value) async {
    tags.firstWhere((g) => g.id == id).tag = value;
  }

  Future<int> addTag(String value) async {
    final newId = tags.isEmpty
        ? 1
        : tags.last.id + 1;

    tags.add(
      CeramicTagDto(
        id: newId,
        ceramicId: 0,
        tag: value,
      ),
    );

    return newId;
  }

  Future<void> removeTag(int id) async {
    tags.removeWhere((g) => g.id == id);
  }

  void setNotes(String value) {
    notes = value;
  }

  void setRating(int value) {
    rating = value;
  }

  void setStage(int value) {
    stageId = value;
  }

  void setDimension(String field, String value) {
    final displayValue = value.trim().isEmpty ? null : double.tryParse(value);
    final parsed = displayValue == null
        ? null
        : Measurement.lengthToCentimeters(
            displayValue,
            AppSettingsController.instance.measurementSystem,
          );
    switch (field) {
      case 'height':
        heightCm = parsed;
        return;
      case 'width':
        widthCm = parsed;
        return;
      case 'depth':
        depthCm = parsed;
        return;
      case 'diameter':
        diameterCm = parsed;
        return;
    }
  }

  void setOutcomeNote(String value) {
    outcomeNote = value;
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

  Future<CeramicDto> create() async{
    CeramicDto ceramicDto = CeramicDto(
      title: title,
      clayTypeId: clayTypeId,
      weight: weight,
      note: notes,
      rating: rating,
      stageId: stageId,
      tags: tags,
      glazes: glazes,
      images: [],
      id: 0,
      heightCm: heightCm,
      widthCm: widthCm,
      depthCm: depthCm,
      diameterCm: diameterCm,
      outcomeNote: outcomeNote,
    );
    final created =
        await CeramicRepository.createCeramic(ceramic: ceramicDto, images: images);
    await cleanupImages();
    return created;
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
