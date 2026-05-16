import 'dart:io';

import 'package:ceramic_app/extensions/extensions.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/objects/image_dto.dart';
import 'package:ceramic_app/repositories/glaze_entry_repository.dart';
import 'package:ceramic_app/repositories/tag_repository.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';

class CeramicViewPageController extends ChangeNotifier{
  List<StageDto> stages = [];

  late CeramicDto ceramic;

  bool hasChanged = false;

  bool _isLoading = false;
  String? _error;

  Future<void> load(CeramicDto? ceramicDto, List<StageDto>? stages) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      ceramicDto ??= await CeramicRepository.getCeramic(ceramic.id);

      ceramic = ceramicDto;
      if(stages != null) this.stages = stages;

      ceramicDto.stageId = this.stages.where((e) => e.id == ceramic.stageId,).first.id;
    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ================= Setters =================

  Future<bool> setTitle(String value) async {
    final oldValue = ceramic.title;
    try {
      ceramic.title = value;
      notifyListeners();
      await CeramicRepository.updateCeramic(ceramic: ceramic);
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.title = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setClayType(int value) async {
    final oldValue = ceramic.clayTypeId;
    try {
      ceramic.clayTypeId = value;
      notifyListeners();
      await CeramicRepository.updateCeramic(ceramic: ceramic);
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.clayTypeId = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setWeight(String value) async {
    final oldValue = ceramic.weight;
    try {
      ceramic.weight = double.tryParse(value) ?? 0.0;
      notifyListeners();
      await CeramicRepository.updateCeramic(ceramic: ceramic);
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.weight = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGlaze(int id, String value) async {
    final oldGlazes = ceramic.glazes.copy();
    try {
      int index = ceramic.glazes.indexWhere((e) => e.id == id);
      ceramic.glazes[index] = await GlazeEntryRepository.editGlazeNoteEntry(ceramic.id, ceramic.glazes[index].id, value);
      notifyListeners();
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.glazes = oldGlazes;
      notifyListeners();
      return false;
    }
  }

  Future<int> addGlaze(int glazeId) async {
    final oldGlazes = ceramic.glazes.copy();
    try {
      ceramic.glazes.add(await GlazeEntryRepository.addGlazeNoteEntry(ceramic.id, glazeId, ""));
      notifyListeners();
      hasChanged = true;
      return ceramic.glazes.last.id;
    } catch (e) {
      ceramic.glazes = oldGlazes;
      notifyListeners();
      return -1;
    }
  }

  Future<bool> removeGlaze(int id) async {
    final oldGlazes = ceramic.glazes.copy();
    try {
      await GlazeEntryRepository.removeGlazeNoteEntry(ceramic.id, id);
      ceramic.glazes.removeWhere((e) => e.id == id);
      notifyListeners();
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.glazes = oldGlazes;
      notifyListeners();
      return false;
    }
  }

  Future<int> addTag(String value) async {
    final oldTags = ceramic.tags.copy();
    try {
      ceramic.tags.add(await TagRepository.addTag(ceramic.id, value));
      notifyListeners();
      hasChanged = true;
      return ceramic.tags.last.id;
    } catch (e) {
      ceramic.tags = oldTags;
      notifyListeners();
      return -1;
    }
  }

  Future<bool> removeTag(int id) async {
    final oldTags = ceramic.tags.copy();
    try {
      await TagRepository.removeTag(ceramic.id, id);
      ceramic.tags.removeWhere((e) => e.id == id);
      notifyListeners();
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.tags = oldTags;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setNotes(String value) async {
    final oldValue = ceramic.note;
    try {
      ceramic.note = value;
      notifyListeners();
      await CeramicRepository.updateCeramic(ceramic: ceramic);
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.note = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setRating(int value) async {
    final oldValue = ceramic.rating;
    try {
      ceramic.rating = value;
      notifyListeners();
      await CeramicRepository.updateCeramic(ceramic: ceramic);
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.rating = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setStage(int value) async {
    final oldValue = ceramic.stageId;
    try {
      ceramic.stageId = value;
      notifyListeners();
      await CeramicRepository.updateCeramic(ceramic: ceramic);
      hasChanged = true;
      return true;
    } catch (e) {
      ceramic.stageId = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadImage(File file) async {
    List<ImageDto> oldImages = ceramic.images.copy();
    try {
      final image = await CeramicRepository.uploadCeramicImage(
        ceramicId: ceramic.id,
        file: file,
      );

      ceramic.images.add(image);
      hasChanged = true;
      notifyListeners();
      return true;

    } catch (e) {
      ceramic.images = oldImages;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteImage(ImageDto image) async {
    List<ImageDto> oldImages = ceramic.images.copy();
    try {
      await CeramicRepository.deleteCeramicImage(
        image: image,
      );

      ceramic.images.removeWhere((e) => e.id == image.id);
      hasChanged = true;
      notifyListeners();
      return true;

    } catch (e) {
      ceramic.images = oldImages;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCeramic() async {
    try {
      await CeramicRepository.deleteCeramic(ceramic.id);
      hasChanged = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}