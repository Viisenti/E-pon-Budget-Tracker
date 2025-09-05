import 'package:flutter/foundation.dart';
import '../models/category.dart' as app_models;
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/sync_service.dart';

class BudgetProvider with ChangeNotifier {
  final SyncService _syncService = SyncService();
  
  List<app_models.Category> _categories = [];
  List<Budget> _budgets = [];
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<app_models.Category> get categories => _categories;
  List<Budget> get budgets => _budgets;
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Analytics getters
  double get totalBudgetAmount => _budgets.where((b) => b.isActive).fold(0.0, (sum, b) => sum + b.budgetAmount);
  double get totalSpentAmount => _expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get remainingBudget => totalBudgetAmount - totalSpentAmount;

  List<Expense> get recentExpenses => _expenses.take(5).toList();

  // Initialize provider
  Future<void> initialize() async {
    await _syncService.initialize();
    await loadData();
  }

  // Load all data from local database
  Future<void> loadData() async {
    _setLoading(true);
    try {
      _categories = await _syncService.getCategories();
      _budgets = await _syncService.getBudgets();
      _expenses = await _syncService.getExpenses();
      _error = null;
      
      // Debug: Print categories count
      if (kDebugMode) {
        print('Loaded ${_categories.length} categories');
        for (var cat in _categories) {
          print('Category: ${cat.name} - ${cat.categoryId}');
        }
      }
    } catch (e) {
      _error = 'Failed to load data: $e';
      if (kDebugMode) {
        print('Error loading data: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Category operations
  Future<void> addCategory(app_models.Category category) async {
    try {
      await _syncService.createCategory(category);
      _categories.add(category);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add category: $e';
      notifyListeners();
    }
  }

  Future<void> updateCategory(app_models.Category category) async {
    try {
      await _syncService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.categoryId == category.categoryId);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _syncService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.categoryId == categoryId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
    }
  }

  // Budget operations
  Future<void> addBudget(Budget budget) async {
    try {
      await _syncService.createBudget(budget);
      _budgets.add(budget);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add budget: $e';
      notifyListeners();
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await _syncService.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.budgetId == budget.budgetId);
      if (index != -1) {
        _budgets[index] = budget;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update budget: $e';
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _syncService.deleteBudget(budgetId);
      _budgets.removeWhere((b) => b.budgetId == budgetId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete budget: $e';
      notifyListeners();
    }
  }

  // Expense operations
  Future<void> addExpense(Expense expense) async {
    try {
      await _syncService.createExpense(expense);
      _expenses.insert(0, expense); // Add to beginning for recent expenses
      
      // Update budget spent amount locally for immediate UI update
      final budgets = _budgets.where((b) => b.categoryId == expense.categoryId && b.isActive);
      final budget = budgets.isNotEmpty ? budgets.first : null;
      if (budget != null) {
        final updatedBudget = budget.copyWith(
          spentAmount: budget.spentAmount + expense.amount,
          updatedAt: DateTime.now(),
        );
        final index = _budgets.indexWhere((b) => b.budgetId == budget.budgetId);
        if (index != -1) {
          _budgets[index] = updatedBudget;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add expense: $e';
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _syncService.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.expenseId == expense.expenseId);
      if (index != -1) {
        _expenses[index] = expense;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update expense: $e';
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      final expenses = _expenses.where((e) => e.expenseId == expenseId);
      final expense = expenses.isNotEmpty ? expenses.first : null;
      await _syncService.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.expenseId == expenseId);
      
      // Update budget spent amount locally
      if (expense != null) {
        final budgets = _budgets.where((b) => b.categoryId == expense.categoryId && b.isActive);
        final budget = budgets.isNotEmpty ? budgets.first : null;
        if (budget != null) {
          final updatedBudget = budget.copyWith(
            spentAmount: (budget.spentAmount - expense.amount).clamp(0.0, double.infinity),
            updatedAt: DateTime.now(),
          );
          final index = _budgets.indexWhere((b) => b.budgetId == budget.budgetId);
          if (index != -1) {
            _budgets[index] = updatedBudget;
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete expense: $e';
      notifyListeners();
    }
  }

  // Helper methods
  app_models.Category? getCategoryById(String categoryId) {
    final categories = _categories.where((c) => c.categoryId == categoryId);
    return categories.isNotEmpty ? categories.first : null;
  }

  Budget? getBudgetById(String budgetId) {
    final budgets = _budgets.where((b) => b.budgetId == budgetId);
    return budgets.isNotEmpty ? budgets.first : null;
  }

  Budget? getBudgetByCategory(String categoryId) {
    final budgets = _budgets.where((b) => b.categoryId == categoryId && b.isActive);
    return budgets.isNotEmpty ? budgets.first : null;
  }

  List<Expense> getExpensesByCategory(String categoryId) {
    return _expenses.where((e) => e.categoryId == categoryId).toList();
  }

  double getSpentAmountByCategory(String categoryId) {
    return _expenses.where((e) => e.categoryId == categoryId).fold(0.0, (sum, e) => sum + e.amount);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
