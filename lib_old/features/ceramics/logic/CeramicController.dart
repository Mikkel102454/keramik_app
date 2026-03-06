import 'package:flutter/material.dart';
import 'package:kemik_app/classes/ceramic_glaze_note_dto.dart';
import 'package:kemik_app/classes/ceramic_tag_dto.dart';
import 'package:kemik_app/classes/stage_dto.dart';

import '../../../classes/ceramic_dto.dart';
import '../../../network/ceramic.dart';


// Not used ill do that later
class CeramicController extends ChangeNotifier{
  late CeramicDto _ceramic;

  late int stage;
  int rating = 0;

  String title = '';
  String pageTitle = '';
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

      stage = _ceramic.stage;
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

  Future<void> updateStage(int stageId) async {
    final oldStage = stage;
    stage = stageId;
    notifyListeners();
    try {
      throw Exception("test");

      await setProgress(_ceramic.id, stageId);
    } catch (e) {
      stage = oldStage;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTitleLocal(String newTitle) async {
    pageTitle = newTitle;
    notifyListeners();
  }

  Future<void> updateTitle(String newTitle) async {
    final oldTitle = title;
    title = newTitle;
    pageTitle = newTitle;
    notifyListeners();
    try {
      throw Exception("test");

      await renameCeramic(_ceramic.id, newTitle);
    } catch (e) {
      title = oldTitle;
      pageTitle = oldTitle;
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

    // Prevent duplicates
    final uniqueTags = newTags.toSet();
    if (uniqueTags.length != newTags.length) {
      throw Exception("Duplicate tags are not allowed.");
    }

    _tags = newTags
        .map((t) => CeramicTagDto(
      id: -1,
      tag: t,
      ceramicId: -1,
    ))
        .toList();

    notifyListeners();

    try {
      for (var tag in oldTags) {
        if (!newTags.contains(tag.tag)) {
          await removeTag(_ceramic.id, tag.id);
        }
      }

      for (var tag in newTags) {
        if (!oldTags.any((element) => element.tag == tag)) {
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

  Future<void> updateGlaze(int index, String value) async {
    final oldGlaze = _glazes[index];

    try {
      throw Exception("test");

      final newGlaze = await editGlazeNote(_ceramic.id, oldGlaze.id, value);
      _glazes[index] = newGlaze;
    } catch (e) {
      _glazes[index] = oldGlaze;
      rethrow;
    }
  }

  Future<void> addGlaze(int index) async {
  }

  Future<void> removeGlaze(int index) async {
  }

  bool get isLoading => _isLoading;
  CeramicDto get ceramic => _ceramic;
  String? get error => _error;

  List<StageDto> get stages => _stages;
  List<CeramicGlazeNoteDto> get glazes => _glazes;
  List<CeramicTagDto> get tags => _tags;
}
