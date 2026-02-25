import 'package:flutter/cupertino.dart';
import 'package:kemik_app/classes/category_dto.dart';
import 'package:kemik_app/pages/PageManager.dart';

import '../../../pages/WIPPage.dart';

class CategoryController extends ChangeNotifier{
  List<CategoryDto> _categories = [];

  bool _isLoading = false;
  String? _error = null;

  void createCategory(CategoryDto category){

  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = [];
      _categories.add(
        CategoryDto(
          title: "Work In Progress",
          page: () => const WIPPage(),
        ),
      );
      _categories.add(
        CategoryDto(
          title: "Finished Work",
          page: () => const WIPPage(),
        )
      );
      _categories.add(
        CategoryDto(
          title: "My Glazes",
          page: () => const WIPPage(),
        )
      );
      _categories.add(
        CategoryDto(
          title: "My Clays",
          page: () => const WIPPage(),
        )
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
  bool get isLoading => _isLoading;

  List<CategoryDto> get categories => _categories;

  String? get error => _error;


}