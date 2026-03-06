import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_glaze_note_dto.dart';
import 'package:ceramic_app/objects/ceramic_tag_dto.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';

class CeramicViewPageController extends ChangeNotifier{
  List<StageDto> stages = [];
  List<CeramicTagDto> tags = [];
  List<CeramicGlazeNoteDto> glazes = [];

  late int ceramicIndex;

  late StageDto stage;
  late CeramicDto ceramic;

  bool hasChanged = false;

  bool _isLoading = false;
  String? _error;

  Future<void> load(CeramicDto? ceramicDto, List<StageDto>? stages) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      ceramicDto ??= await CeramicRepository.getCeramic(ceramicIndex);

      ceramic = ceramicDto;
      ceramicIndex = ceramic.id;
      tags = await CeramicRepository.getTags(ceramicIndex);
      glazes = await CeramicRepository.getGlazeNotes(ceramicIndex);
      if(stages != null) this.stages = stages;

      stage = this.stages.where((e) => e.id == ceramic.stage,).first;
    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ================= Setters =================

  Future<void> setTitle(String value) async {
    final oldValue = ceramic.title;
    try {
      ceramic.title = value;
      notifyListeners();
      await CeramicRepository.renameCeramic(ceramicIndex, value);
      hasChanged = true;
    } catch (e) {
      ceramic.title = oldValue;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setClayType(String value) async {
    final oldValue = ceramic.type;
    try {
      ceramic.type = value;
      notifyListeners();
      await CeramicRepository.setType(ceramicIndex, value);
      hasChanged = true;
    } catch (e) {
      ceramic.type = oldValue;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setWeight(double value) async {
    final oldValue = ceramic.weight;
    try {
      ceramic.weight = value;
      notifyListeners();
      await CeramicRepository.setWeight(ceramicIndex, value);
      hasChanged = true;
    } catch (e) {
      ceramic.weight = oldValue;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGlaze(int index, String value) async {
    glazes[index] = await CeramicRepository.editGlazeNote(ceramicIndex, glazes[index].id, value);
    hasChanged = true;
  }

  Future<void> addGlaze() async {
    glazes.add(await CeramicRepository.addGlazeNote(ceramicIndex, ""));
    hasChanged = true;
  }

  Future<void> removeGlaze(int index) async {
    final removed = glazes[index];
    try {
      glazes.removeAt(index);
      notifyListeners();

      await CeramicRepository.removeGlazeNote(ceramicIndex, removed.id);
      hasChanged = true;
    } catch (e) {
      glazes.insert(index, removed);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTag(int index, String value) async {
    tags[index] = await CeramicRepository.editTag(ceramicIndex, tags[index].id, value);
    hasChanged = true;
  }

  Future<void> addTag(String value) async {
    tags.add(await CeramicRepository.addTag(ceramicIndex, value));
    hasChanged = true;
  }

  Future<void> removeTag(int index) async {
    await CeramicRepository.removeTag(ceramicIndex, tags[index].id); tags.removeAt(index);
    hasChanged = true;
  }

  Future<void> setNotes(String value) async {
    final oldValue = ceramic.note;
    try {
      ceramic.note = value;
      notifyListeners();
      await CeramicRepository.setNote(ceramicIndex, value);
      hasChanged = true;
    } catch (e) {
      ceramic.note = oldValue;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setRating(int value) async {
    final oldValue = ceramic.rate;
    try {
      ceramic.rate = value;
      notifyListeners();
      await CeramicRepository.setRate(ceramicIndex, value);
      hasChanged = true;
    } catch (e) {
      ceramic.rate = oldValue;
      notifyListeners();
      //rethrow;
    }
  }

  Future<void> setStage(StageDto value) async {
    final oldValue = stage;
    try {
      stage = value;
      notifyListeners();
      await CeramicRepository.setProgress(ceramicIndex, value.id);
      hasChanged = true;
    } catch (e) {
      stage = oldValue;
      notifyListeners();
      //rethrow;
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
}