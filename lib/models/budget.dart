class Budget {
  final String budgetId;
  final String? userId;
  final String? categoryId;
  final String budgetName;
  final double budgetAmount;
  final String? periodType; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final double spentAmount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  Budget({
    required this.budgetId,
    this.userId,
    this.categoryId,
    required this.budgetName,
    required this.budgetAmount,
    this.periodType,
    required this.startDate,
    this.endDate,
    this.spentAmount = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.needsSync = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'budget_id': budgetId,
      'user_id': userId,
      'category_id': categoryId,
      'budget_name': budgetName,
      'budget_amount': budgetAmount,
      'period_type': periodType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'spent_amount': spentAmount,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      budgetId: map['budget_id'],
      userId: map['user_id'],
      categoryId: map['category_id'],
      budgetName: map['budget_name'],
      budgetAmount: (map['budget_amount'] as num).toDouble(),
      periodType: map['period_type'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      spentAmount: (map['spent_amount'] as num?)?.toDouble() ?? 0.0,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      needsSync: map['needs_sync'] == 1,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'budget_id': budgetId,
      'user_id': userId,
      'category_id': categoryId,
      'budget_name': budgetName,
      'budget_amount': budgetAmount,
      'period_type': periodType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'spent_amount': spentAmount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Budget copyWith({
    String? budgetId,
    String? userId,
    String? categoryId,
    String? budgetName,
    double? budgetAmount,
    String? periodType,
    DateTime? startDate,
    DateTime? endDate,
    double? spentAmount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) {
    return Budget(
      budgetId: budgetId ?? this.budgetId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      budgetName: budgetName ?? this.budgetName,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      spentAmount: spentAmount ?? this.spentAmount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  double get remainingAmount => budgetAmount - spentAmount;
  double get progressPercentage => budgetAmount > 0 ? (spentAmount / budgetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spentAmount > budgetAmount;
}
