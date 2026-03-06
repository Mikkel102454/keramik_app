import 'package:flutter/material.dart';

import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';

class CeramicCreatePageController extends ChangeNotifier{
  List<StageDto> stages = [];

  String title = '';
  String clayType = '';
  double weight = 0.0;
  List<String> glazes = [];
  List<String> tags = [];
  String notes = '';
  int rating = 0;
  StageDto? stage;

  bool _isLoading = false;
  String? _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      stages = await CeramicRepository.getStages();
      stage = stages.first;
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

  void setClayType(String value) {
    clayType = value;
  }

  void setWeight(String value) {
    weight = double.tryParse(value) ?? 0.0;
  }

  Future<void> updateGlaze(int index, String value) async {
    glazes[index] = value;
  }

  Future<void> addGlaze() async {
    glazes.add("");
  }

  Future<void> removeGlaze(int index) async {
    glazes.removeAt(index);
  }

  Future<void> updateTag(int index, String value) async {
    tags[index] = value;
  }

  Future<void> addTag(String value) async {
    tags.add(value);
  }

  Future<void> removeTag(int index) async {
    tags.removeAt(index);
  }

  void setNotes(String value) {
    notes = value;
  }

  void setRating(int value) {
    rating = value;
  }

  void setStage(StageDto value) {
    stage = value;
  }

  Future<void> create() async{
    return await CeramicRepository.createCeramic(
      title: title,
      clayType: clayType,
      weight: weight,
      note: notes,
      rating: rating,
      stageId: stage!.id,
      tags: tags,
      glazes: glazes,
    );
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}