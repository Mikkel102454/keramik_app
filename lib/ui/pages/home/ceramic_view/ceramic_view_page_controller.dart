import 'dart:io';

import 'package:ceramic_app/extensions/extensions.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/image_dto.dart';
import 'package:ceramic_app/objects/ceramic_firing_dto.dart';
import 'package:ceramic_app/objects/ceramic_stage_history_dto.dart';
import 'package:ceramic_app/repositories/ceramic_firing_repository.dart';
import 'package:ceramic_app/repositories/ceramic_stage_history_repository.dart';
import 'package:ceramic_app/repositories/glaze_entry_repository.dart';
import 'package:ceramic_app/repositories/tag_repository.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/utils/measurement.dart';

import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';

class CeramicViewPageController extends ChangeNotifier{
  List<StageDto> stages = [];

  late CeramicDto ceramic;
  List<CeramicFiringDto> firings = [];
  List<CeramicStageHistoryDto> stageHistory = [];

  bool hasChanged = false;

  bool _isLoading = false;
  String? _error;

  Future<void> load(CeramicDto? ceramicDto, List<StageDto>? stages) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ceramicId = ceramicDto?.id ?? ceramic.id;
      final results = await Future.wait<dynamic>([
        CeramicRepository.getCeramic(ceramicId),
        CeramicFiringRepository.getFirings(ceramicId),
        CeramicStageHistoryRepository.getHistory(ceramicId),
      ]);
      ceramic = results[0] as CeramicDto;
      firings = results[1] as List<CeramicFiringDto>;
      stageHistory = results[2] as List<CeramicStageHistoryDto>;
      if(stages != null) this.stages = stages;

      ceramic.stageId = this.stages.where((e) => e.id == ceramic.stageId,).first.id;
    } catch (e){
      _error = 'We could not load this ceramic.';
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

  Future<bool> updateGlaze(int id, String value, int coatCount) async {
    final oldGlazes = ceramic.glazes.copy();
    try {
      int index = ceramic.glazes.indexWhere((e) => e.id == id);
      ceramic.glazes[index] = await GlazeEntryRepository.editGlazeNoteEntry(
        ceramic.id,
        ceramic.glazes[index].id,
        note: value,
        coatCount: coatCount,
      );
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
      ceramic.glazes.add(await GlazeEntryRepository.addGlazeNoteEntry(
        ceramic.id,
        glazeId,
        "",
        layerOrder: ceramic.glazes.length + 1,
        coatCount: 1,
      ));
      notifyListeners();
      hasChanged = true;
      return ceramic.glazes.last.id;
    } catch (e) {
      ceramic.glazes = oldGlazes;
      notifyListeners();
      return -1;
    }
  }

  Future<bool> moveGlaze(int id, int direction) async {
    ceramic.glazes.sort((a, b) => a.layerOrder.compareTo(b.layerOrder));
    final index = ceramic.glazes.indexWhere((entry) => entry.id == id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= ceramic.glazes.length) return false;
    final oldGlazes = ceramic.glazes.copy();
    final moved = ceramic.glazes[index];
    final other = ceramic.glazes[target];
    final movedOrder = moved.layerOrder;
    final otherOrder = other.layerOrder;
    moved.layerOrder = otherOrder;
    other.layerOrder = movedOrder;
    ceramic.glazes.sort((a, b) => a.layerOrder.compareTo(b.layerOrder));
    notifyListeners();
    try {
      await GlazeEntryRepository.editGlazeNoteEntry(
        ceramic.id,
        moved.id,
        layerOrder: moved.layerOrder,
      );
      await GlazeEntryRepository.editGlazeNoteEntry(
        ceramic.id,
        other.id,
        layerOrder: other.layerOrder,
      );
      hasChanged = true;
      return true;
    } catch (_) {
      moved.layerOrder = movedOrder;
      other.layerOrder = otherOrder;
      ceramic.glazes = oldGlazes;
      try {
        ceramic = await CeramicRepository.getCeramic(ceramic.id);
      } catch (_) {}
      notifyListeners();
      return false;
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

  Future<bool> setDimension(String field, String value) async {
    final oldValues = [
      ceramic.heightCm,
      ceramic.widthCm,
      ceramic.depthCm,
      ceramic.diameterCm,
    ];
    final displayValue = value.trim().isEmpty ? null : double.tryParse(value);
    final parsed = displayValue == null
        ? null
        : Measurement.lengthToCentimeters(
            displayValue,
            AppSettingsController.instance.measurementSystem,
          );
    switch (field) {
      case 'height':
        ceramic.heightCm = parsed;
        break;
      case 'width':
        ceramic.widthCm = parsed;
        break;
      case 'depth':
        ceramic.depthCm = parsed;
        break;
      case 'diameter':
        ceramic.diameterCm = parsed;
        break;
    }
    notifyListeners();
    try {
      await CeramicRepository.updateCeramicDetails(ceramic: ceramic);
      hasChanged = true;
      return true;
    } catch (_) {
      ceramic.heightCm = oldValues[0];
      ceramic.widthCm = oldValues[1];
      ceramic.depthCm = oldValues[2];
      ceramic.diameterCm = oldValues[3];
      notifyListeners();
      return false;
    }
  }

  Future<bool> setOutcomeNote(String value) async {
    final oldValue = ceramic.outcomeNote;
    ceramic.outcomeNote = value;
    notifyListeners();
    try {
      await CeramicRepository.updateCeramicDetails(ceramic: ceramic);
      hasChanged = true;
      return true;
    } catch (_) {
      ceramic.outcomeNote = oldValue;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveFiring(CeramicFiringDto firing) async {
    try {
      final saved = firing.id == 0
          ? await CeramicFiringRepository.create(ceramic.id, firing)
          : await CeramicFiringRepository.update(ceramic.id, firing);
      final index = firings.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        firings.insert(0, saved);
      } else {
        firings[index] = saved;
      }
      firings.sort((a, b) {
        final left = a.firingDate ?? DateTime(1970);
        final right = b.firingDate ?? DateTime(1970);
        final byDate = right.compareTo(left);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
      hasChanged = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteFiring(int firingId) async {
    try {
      await CeramicFiringRepository.delete(ceramic.id, firingId);
      firings.removeWhere((item) => item.id == firingId);
      hasChanged = true;
      notifyListeners();
      return true;
    } catch (_) {
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
      stageHistory = await CeramicStageHistoryRepository.getHistory(ceramic.id);
      notifyListeners();
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
