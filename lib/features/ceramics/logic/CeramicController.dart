import 'package:flutter/material.dart';
import 'package:kemik_app/classes/cemaric_glaze_note_dto.dart';
import 'package:kemik_app/classes/ceramic_tag_dto.dart';
import 'package:kemik_app/classes/stage_dto.dart';

import '../../../classes/ceramic_dto.dart';
import '../../../network/ceramic.dart';

class CeramicController extends ChangeNotifier{
  late CeramicDto _ceramic;

  late StageDto stage;
  int rating = 0;

  String title = '';
  String clayType = '';
  double weight = 0.0;
  String notes = '';

  List<CeramicTagDto> _tags = [];
  List<CeramicGlazeNoteDto> _glazes = [];
  List<StageDto> _stages = [];

  bool _isLoading = true;
  String? _error;

  CeramicController(CeramicDto ceramic) {
    _ceramic = ceramic;
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ceramic = await getCeramic(_ceramic.id);
      _tags = await getTags(_ceramic.id);
      _glazes = await getGlazeNotes(_ceramic.id);
      _stages = await getStages();

      stage = _stages.firstWhere((s) => s.id == _ceramic.stage);
      rating = _ceramic.rate.toInt();
      title = _ceramic.title;
      clayType = _ceramic.type;
      weight = _ceramic.weight;
      notes = _ceramic.note;

    } catch (e){
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> delete() async {
    await deleteCeramic(_ceramic.id);
  }

  Future<void> updateStage(StageDto newStage) async {
    final oldStage = stage;
    stage = newStage;
    notifyListeners();
    try {
      throw Exception("test");

      await setProgress(_ceramic.id, newStage.id);
    } catch (e) {
      stage = oldStage;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTitle(String newTitle) async {
    final oldTitle = title;
    title = newTitle;
    notifyListeners();
    try {
      throw Exception("test");

      await renameCeramic(_ceramic.id, newTitle);
    } catch (e) {
      title = oldTitle;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateType(String newType) async {
    final oldType = clayType;
    clayType = newType;
    notifyListeners();
    try {
      throw Exception("test");

      await setType(_ceramic.id, newType);
    } catch(e) {
      clayType = oldType;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateWeight(double newWeight) async {
    final oldWeight = weight;
    weight = newWeight;
    notifyListeners();
    try {
      throw Exception("test");
      await setWeight(_ceramic.id, newWeight);
    } catch (e) {
      weight = oldWeight;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRating(int newRating) async {
    final oldRating = rating;
    rating = newRating;
    notifyListeners();
    try {
      throw Exception("test");

      await setRate(_ceramic.id, newRating);
    } catch (e) {
      rating = oldRating;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateNotes(String newNotes) async {
    final oldNotes = notes;
    notes = newNotes;
    notifyListeners();
    try {
      throw Exception("test");

      await setNote(_ceramic.id, newNotes);
    } catch (e) {
      notes = oldNotes;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTags(List<String> newTags) async {
    final oldTags = List<CeramicTagDto>.from(_tags);
    try {
      throw Exception("test");

      final uniqueTags = newTags.toSet();
      if (uniqueTags.length != newTags.length) {
        throw Exception("Duplicate tags are not allowed.");
      }

      for (var tag in _tags) {
        if (!newTags.contains(tag.tag)) {
          await removeTag(_ceramic.id, tag.id);
        }
      }
      for (var tag in newTags) {
        if (!_tags.any((element) => element.tag == tag)) {
          await addTag(_ceramic.id, tag);
        }
      }
      _tags = await getTags(_ceramic.id);
      notifyListeners();
    } catch (e) {
      _tags = oldTags;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGlazes(List<String> newGlazes) async {
    final oldGlazes = List<CeramicGlazeNoteDto>.from(_glazes);
    try {
      throw Exception("test");

      //find removed glazes
      for (var glaze in _glazes) {
        if (!newGlazes.contains(glaze.note)) {
          await removeGlazeNote(_ceramic.id, glaze.id);
        }
      }

      //find added glazes
      for (var glaze in newGlazes) {
        if (!_glazes.any((element) => element.note == glaze)) {
          await addGlazeNote(_ceramic.id, glaze);
        }
      }
       _glazes = await getGlazeNotes(_ceramic.id);
      notifyListeners();
    } catch (e) {
      _glazes = oldGlazes;
      notifyListeners();
      rethrow;
    }
  }

  bool get isLoading => _isLoading;
  CeramicDto get ceramic => _ceramic;
  String? get error => _error;

  List<StageDto> get stages => _stages;
  List<CeramicGlazeNoteDto> get glazes => _glazes;
  List<CeramicTagDto> get tags => _tags;
}
