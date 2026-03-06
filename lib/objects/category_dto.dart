import 'package:flutter/cupertino.dart';

class CategoryDto {
  final String title;
  final Widget Function()? page;

  CategoryDto({
    required this.title,
    this.page,
  });
}