import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:kemik_app/classes/category_dto.dart';
import 'package:kemik_app/classes/stage_dto.dart';

import '../../../network/ceramic.dart';

class CeramicCreateController extends ChangeNotifier{
  String title = '';
  String clayType = '';
  double weight = 0.0;
  String notes = '';
  int rating = 0;
  StageDto? stage;
  List<String> tags = [];
  List<String> glazes = [];


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