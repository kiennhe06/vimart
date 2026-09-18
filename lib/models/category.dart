/// Danh mục sản phẩm.
class Category {
  Category({required this.id, required this.name, required this.slug, this.icon});

  final int id;
  final String name;
  final String slug;
  final String? icon;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        icon: json['icon'] as String?,
      );
}
