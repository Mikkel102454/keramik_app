/* ---------- Category Model ---------- */
class CategoryEntry {
  final int id;
  final int itemCount;
  final String title;

  CategoryEntry({
    required this.id,
    required this.itemCount,
    required this.title,
  });

  factory CategoryEntry.fromJson(Map<String, dynamic> json) {
    return CategoryEntry(
      id: json['id'],
      itemCount: json['itemCount'],
      title: json['title'],
    );
  }
}

/* ---------- Main Response Model ---------- */
class CategoryList {
  final List<CategoryEntry> categories;
  final int categoryCount;

  CategoryList({
    required this.categories,
    required this.categoryCount,
  });

  factory CategoryList.fromJson(Map<String, dynamic> json) {
    return CategoryList(
      categories: (json['categories'] as List)
          .map((e) => CategoryEntry.fromJson(e))
          .toList(),
      categoryCount: json['categoryCount'],
    );
  }
}