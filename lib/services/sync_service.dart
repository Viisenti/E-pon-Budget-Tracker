import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_helper.dart';
import 'supabase_service.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/expense.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Initialize sync service and start monitoring connectivity
  Future<void> initialize() async {
    await _startConnectivityMonitoring();
    await _startPeriodicSync();
  }

  // Start monitoring connectivity changes
  Future<void> _startConnectivityMonitoring() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        if (result != ConnectivityResult.none && !_isSyncing) {
          await syncPendingData();
        }
      },
    );
  }

  // Start periodic sync every 30 seconds when online
  Future<void> _startPeriodicSync() async {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (await isOnline() && !_isSyncing) {
        await syncPendingData();
      }
    });
  }

  // Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Double-check with Supabase connection
      return await _supabaseService.isConnected();
    } catch (e) {
      return false;
    }
  }

  // Main sync function - syncs all pending data
  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    try {
      if (!await isOnline()) {
        return;
      }

      // Sync categories
      await _syncCategories();
      
      // Sync budgets
      await _syncBudgets();
      
      // Sync expenses
      await _syncExpenses();
      
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Sync categories
  Future<void> _syncCategories() async {
    try {
      final unsyncedCategories = await _dbHelper.getUnsyncedCategories();
      
      if (unsyncedCategories.isNotEmpty) {
        await _supabaseService.syncCategories(unsyncedCategories);
        
        // Mark as synced in local database
        for (final category in unsyncedCategories) {
          await _dbHelper.markAsSynced('categories', category.categoryId);
        }
      }
    } catch (e) {
      print('Category sync error: $e');
    }
  }

  // Sync budgets
  Future<void> _syncBudgets() async {
    try {
      final unsyncedBudgets = await _dbHelper.getUnsyncedBudgets();
      
      if (unsyncedBudgets.isNotEmpty) {
        await _supabaseService.syncBudgets(unsyncedBudgets);
        
        // Mark as synced in local database
        for (final budget in unsyncedBudgets) {
          await _dbHelper.markAsSynced('budgets', budget.budgetId);
        }
      }
    } catch (e) {
      print('Budget sync error: $e');
    }
  }

  // Sync expenses
  Future<void> _syncExpenses() async {
    try {
      final unsyncedExpenses = await _dbHelper.getUnsyncedExpenses();
      
      if (unsyncedExpenses.isNotEmpty) {
        await _supabaseService.syncExpenses(unsyncedExpenses);
        
        // Mark as synced in local database
        for (final expense in unsyncedExpenses) {
          await _dbHelper.markAsSynced('expenses', expense.expenseId);
        }
      }
    } catch (e) {
      print('Expense sync error: $e');
    }
  }

  // CRUD operations with offline-first approach
  
  // Category operations
  Future<void> createCategory(Category category) async {
    // Always save locally first
    final categoryWithSync = category.copyWith(needsSync: true);
    await _dbHelper.insertCategory(categoryWithSync);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.insertCategory(category);
        await _dbHelper.markAsSynced('categories', category.categoryId);
      } catch (e) {
        print('Failed to sync category immediately: $e');
      }
    }
  }

  Future<void> updateCategory(Category category) async {
    // Always save locally first
    final categoryWithSync = category.copyWith(needsSync: true);
    await _dbHelper.updateCategory(categoryWithSync);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.updateCategory(category);
        await _dbHelper.markAsSynced('categories', category.categoryId);
      } catch (e) {
        print('Failed to sync category update immediately: $e');
      }
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    // Delete locally first
    await _dbHelper.deleteCategory(categoryId);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.deleteCategory(categoryId);
      } catch (e) {
        print('Failed to sync category deletion immediately: $e');
      }
    }
  }

  // Budget operations
  Future<void> createBudget(Budget budget) async {
    // Always save locally first
    final budgetWithSync = budget.copyWith(needsSync: true);
    await _dbHelper.insertBudget(budgetWithSync);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.insertBudget(budget);
        await _dbHelper.markAsSynced('budgets', budget.budgetId);
      } catch (e) {
        print('Failed to sync budget immediately: $e');
      }
    }
  }

  Future<void> updateBudget(Budget budget) async {
    // Always save locally first
    final budgetWithSync = budget.copyWith(needsSync: true);
    await _dbHelper.updateBudget(budgetWithSync);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.updateBudget(budget);
        await _dbHelper.markAsSynced('budgets', budget.budgetId);
      } catch (e) {
        print('Failed to sync budget update immediately: $e');
      }
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    // Delete locally first
    await _dbHelper.deleteBudget(budgetId);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.deleteBudget(budgetId);
      } catch (e) {
        print('Failed to sync budget deletion immediately: $e');
      }
    }
  }

  // Expense operations
  Future<void> createExpense(Expense expense) async {
    // Always save locally first
    final expenseWithSync = expense.copyWith(needsSync: true);
    await _dbHelper.insertExpense(expenseWithSync);
    
    // Update budget spent amount if category matches
    await _updateBudgetSpentAmount(expense.categoryId, expense.amount);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.insertExpense(expense);
        await _dbHelper.markAsSynced('expenses', expense.expenseId);
      } catch (e) {
        print('Failed to sync expense immediately: $e');
      }
    }
  }

  Future<void> updateExpense(Expense expense) async {
    // Always save locally first
    final expenseWithSync = expense.copyWith(needsSync: true);
    await _dbHelper.updateExpense(expenseWithSync);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.updateExpense(expense);
        await _dbHelper.markAsSynced('expenses', expense.expenseId);
      } catch (e) {
        print('Failed to sync expense update immediately: $e');
      }
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    // Delete locally first
    await _dbHelper.deleteExpense(expenseId);
    
    // Try to sync immediately if online
    if (await isOnline()) {
      try {
        await _supabaseService.deleteExpense(expenseId);
      } catch (e) {
        print('Failed to sync expense deletion immediately: $e');
      }
    }
  }

  // Helper method to update budget spent amounts
  Future<void> _updateBudgetSpentAmount(String? categoryId, double amount) async {
    if (categoryId == null) return;
    
    try {
      final budgets = await _dbHelper.getAllBudgets();
      final categoryBudgets = budgets.where((b) => b.categoryId == categoryId && b.isActive);
      final categoryBudget = categoryBudgets.isNotEmpty ? categoryBudgets.first : null;
      
      if (categoryBudget != null) {
        final updatedBudget = categoryBudget.copyWith(
          spentAmount: categoryBudget.spentAmount + amount,
          updatedAt: DateTime.now(),
          needsSync: true,
        );
        await _dbHelper.updateBudget(updatedBudget);
      }
    } catch (e) {
      print('Failed to update budget spent amount: $e');
    }
  }

  // Get local data (always returns local data for offline-first approach)
  Future<List<Category>> getCategories() async {
    return await _dbHelper.getAllCategories();
  }

  Future<List<Budget>> getBudgets() async {
    return await _dbHelper.getAllBudgets();
  }

  Future<List<Expense>> getExpenses() async {
    return await _dbHelper.getAllExpenses();
  }

  // Cleanup
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
