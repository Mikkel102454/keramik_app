import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:kemik_app/classes/category_dto.dart';
import 'package:kemik_app/classes/stage_dto.dart';

import '../../../network/ceramic.dart';

class CeramicCreateController extends ChangeNotifier{
  String title = '';
  String clayType = '';
  double weight = 0.0;
  List<String> glazes = [];
  List<String> tags = [];
  String notes = '';
  int rating = 0;
  StageDto? stage;

  // ================= Setters =================

  void setTitle(String value) {
    title = value;
    notifyListeners();
  }

  void setClayType(String value) {
    clayType = value;
    notifyListeners();
  }

  void setWeight(String value) {
    weight = double.tryParse(value) ?? 0.0;
    notifyListeners();
  }

  Future<void> updateGlaze(int index, String value) async {
  }

  Future<void> addGlaze(int index) async {
  }

  Future<void> removeGlaze(int index) async {
  }

  void setTags(List<String> value) {
    tags = value;
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
    notifyListeners();
  }

  void setRating(int value) {
    rating = value;
    notifyListeners();
  }

  void setStage(StageDto value) {
    stage = value;
    notifyListeners();
  }

  Future<void> create() async{
    return await createCeramic(
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
}