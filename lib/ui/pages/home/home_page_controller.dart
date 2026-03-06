import 'package:ceramic_app/ui/pages/home/ceramic_select/ceramic_select_page.dart';
import 'package:ceramic_app/ui/pages/home/my_clays/my_clays_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:ceramic_app/objects/category_dto.dart';

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
          page: () => const CeramicSelectPage(),
        ),
      );
      _categories.add(
          CategoryDto(
            title: "Finished Work",
            //page: () => const WIPPage(),
          )
      );
      _categories.add(
          CategoryDto(
            title: "My Glazes",
            //page: () => const WIPPage(),
          )
      );
      _categories.add(
          CategoryDto(
            title: "My Clays",
            page: () => const MyClaysPage(),
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