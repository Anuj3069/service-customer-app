class Category {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<Service> services;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.services = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final baseCategory = Category(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '🔧',
      description: json['description'] ?? '',
    );

    return Category(
      id: baseCategory.id,
      name: baseCategory.name,
      icon: baseCategory.icon,
      description: baseCategory.description,
      services: (json['services'] as List? ?? [])
          .map(
            (serviceJson) =>
                Service.fromJson(serviceJson, fallbackCategory: baseCategory),
          )
          .toList(),
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
  final bool allowMonthBooking;

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
    this.allowMonthBooking = false,
  });

  factory Service.fromJson(
    Map<String, dynamic> json, {
    Category? fallbackCategory,
  }) {
    Category? cat;
    if (json['category'] is Map<String, dynamic>) {
      cat = Category.fromJson(json['category']);
    } else {
      cat = fallbackCategory;
    }

    return Service(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      categoryId: json['category'] is String ? json['category'] : cat?.id,
      category: cat,
      isActive: json['isActive'] ?? true,
      allowMonthBooking: json['allowMonthBooking'] ?? false,
    );
  }
}
