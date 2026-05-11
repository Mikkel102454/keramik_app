import 'dart:io';

import 'package:ceramic_app/extensions/extensions.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/ceramic_image_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:ceramic_app/repositories/stage_repository.dart';
import 'package:ceramic_app/utils/file.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
      _error = e.toString();
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
    weight = double.tryParse(value) ?? 0.0;
  }

  Future<void> updateGlaze(int id, String value) async {
    glazes.firstWhere((g) => g.id == id).note = value;
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
      ),
    );

    return newId;
  }

  Future<void> removeGlaze(int id) async {
    glazes.removeWhere((g) => g.id == id);
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
      images.removeAt(imageId);
      notifyListeners();
      return true;

    } catch (e) {
      images = oldImages;
      notifyListeners();
      return false;
    }
  }

  Future<void> create() async{
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
    );
    return await CeramicRepository.createCeramic(ceramic: ceramicDto, images: images);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}