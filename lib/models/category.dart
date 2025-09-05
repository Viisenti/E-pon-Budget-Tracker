class Category {
  final String categoryId;
  final String name;
  final String? description;
  final String? iconName;
  final String? colorCode;
  final bool isDefault;
  final String? createdByUserId;
  final DateTime createdAt;
  final bool needsSync;

  Category({
    required this.categoryId,
    required this.name,
    this.description,
    this.iconName,
    this.colorCode,
    this.isDefault = false,
    this.createdByUserId,
    required this.createdAt,
    this.needsSync = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color_code': colorCode,
      'is_default': isDefault ? 1 : 0,
      'created_by_user_id': createdByUserId,
      'created_at': createdAt.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryId: map['category_id'],
      name: map['name'],
      description: map['description'],
      iconName: map['icon_name'],
      colorCode: map['color_code'],
      isDefault: map['is_default'] == 1,
      createdByUserId: map['created_by_user_id'],
      createdAt: DateTime.parse(map['created_at']),
      needsSync: map['needs_sync'] == 1,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color_code': colorCode,
      'is_default': isDefault,
      'created_by_user_id': createdByUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? categoryId,
    String? name,
    String? description,
    String? iconName,
    String? colorCode,
    bool? isDefault,
    String? createdByUserId,
    DateTime? createdAt,
    bool? needsSync,
  }) {
    return Category(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorCode: colorCode ?? this.colorCode,
      isDefault: isDefault ?? this.isDefault,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }
}
