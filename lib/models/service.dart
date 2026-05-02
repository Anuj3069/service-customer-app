class Category {
  final String id;
  final String name;
  final String icon;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '🔧',
      description: json['description'] ?? '',
    );
  }
}

class Service {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final int duration;
  final List<String> requiredSkills;
  final String? categoryId;
  final Category? category;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.duration,
    required this.requiredSkills,
    this.categoryId,
    this.category,
    this.isActive = true,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    Category? cat;
    if (json['category'] is Map<String, dynamic>) {
      cat = Category.fromJson(json['category']);
    }

    return Service(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      categoryId: json['category'] is String ? json['category'] : null,
      category: cat,
      isActive: json['isActive'] ?? true,
    );
  }
}
