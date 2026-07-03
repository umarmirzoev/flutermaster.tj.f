class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.productCount = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final int productCount;
  final bool active;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      productCount: json['productCount'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }
}
