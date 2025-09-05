class Expense {
  final String expenseId;
  final String? userId;
  final String? categoryId;
  final double amount;
  final String? description;
  final DateTime expenseDate;
  final String? merchantName;
  final String? location;
  final String? paymentMethod;
  final String? receiptImgUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRecurring;
  final String? recurringExpenseId;
  final bool needsSync;

  Expense({
    required this.expenseId,
    this.userId,
    this.categoryId,
    required this.amount,
    this.description,
    required this.expenseDate,
    this.merchantName,
    this.location,
    this.paymentMethod,
    this.receiptImgUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurringExpenseId,
    this.needsSync = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'expense_id': expenseId,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
      'merchant_name': merchantName,
      'location': location,
      'payment_method': paymentMethod,
      'receipt_img_url': receiptImgUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_expense_id': recurringExpenseId,
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      expenseId: map['expense_id'],
      userId: map['user_id'],
      categoryId: map['category_id'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'],
      expenseDate: DateTime.parse(map['expense_date']),
      merchantName: map['merchant_name'],
      location: map['location'],
      paymentMethod: map['payment_method'],
      receiptImgUrl: map['receipt_img_url'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isRecurring: map['is_recurring'] == 1,
      recurringExpenseId: map['recurring_expense_id'],
      needsSync: map['needs_sync'] == 1,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'expense_id': expenseId,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
      'merchant_name': merchantName,
      'location': location,
      'payment_method': paymentMethod,
      'receipt_img_url': receiptImgUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_recurring': isRecurring,
      'recurring_expense_id': recurringExpenseId,
    };
  }

  Expense copyWith({
    String? expenseId,
    String? userId,
    String? categoryId,
    double? amount,
    String? description,
    DateTime? expenseDate,
    String? merchantName,
    String? location,
    String? paymentMethod,
    String? receiptImgUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    String? recurringExpenseId,
    bool? needsSync,
  }) {
    return Expense(
      expenseId: expenseId ?? this.expenseId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      merchantName: merchantName ?? this.merchantName,
      location: location ?? this.location,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptImgUrl: receiptImgUrl ?? this.receiptImgUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
      needsSync: needsSync ?? this.needsSync,
    );
  }
}
