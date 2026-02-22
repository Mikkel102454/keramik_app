import 'package:kemik_app/classes/category.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<CategoryList> fetchCategories() async {
  final url = Uri.parse("127.0.0.1/api/account/categories");

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    return CategoryList.fromJson(decoded);
  } else {
    throw Exception("Failed to load");
  }
}