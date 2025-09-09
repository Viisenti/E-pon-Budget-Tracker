import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/expense.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://wasrcfohojjdaqzrkojh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indhc3JjZm9ob2pqZGFxenJrb2poIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5NzIxNzcsImV4cCI6MjA3MDU0ODE3N30.rupFv1-30HBaed2bh8UnnJkWVk6DbjZJxZ2d347T4Fg';

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Category operations
  Future<List<Category>> getCategories() async {
    try {
      final response = await client
          .from('categories')
          .select()
          .order('created_at', ascending: true);
      
      return (response as List)
          .map((item) => Category.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<void> insertCategory(Category category) async {
    try {
      await client
          .from('categories')
          .insert(category.toSupabaseMap());
    } catch (e) {
      throw Exception('Failed to insert category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await client
          .from('categories')
          .update(category.toSupabaseMap())
          .eq('category_id', category.categoryId);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await client
          .from('categories')
          .delete()
          .eq('category_id', categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Budget operations
  Future<List<Budget>> getBudgets() async {
    try {
      final response = await client
          .from('budgets')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Budget.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch budgets: $e');
    }
  }

  Future<void> insertBudget(Budget budget) async {
    try {
      await client
          .from('budgets')
          .insert(budget.toSupabaseMap());
    } catch (e) {
      throw Exception('Failed to insert budget: $e');
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await client
          .from('budgets')
          .update(budget.toSupabaseMap())
          .eq('budget_id', budget.budgetId);
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await client
          .from('budgets')
          .delete()
          .eq('budget_id', budgetId);
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  // Expense operations
  Future<List<Expense>> getExpenses() async {
    try {
      final response = await client
          .from('expenses')
          .select()
          .order('expense_date', ascending: false);
      
      return (response as List)
          .map((item) => Expense.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  Future<void> insertExpense(Expense expense) async {
    try {
      await client
          .from('expenses')
          .insert(expense.toSupabaseMap());
    } catch (e) {
      throw Exception('Failed to insert expense: $e');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await client
          .from('expenses')
          .update(expense.toSupabaseMap())
          .eq('expense_id', expense.expenseId);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await client
          .from('expenses')
          .delete()
          .eq('expense_id', expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Batch operations for sync
  Future<void> syncCategories(List<Category> categories) async {
    try {
      if (categories.isNotEmpty) {
        await client
            .from('categories')
            .upsert(categories.map((c) => c.toSupabaseMap()).toList());
      }
    } catch (e) {
      throw Exception('Failed to sync categories: $e');
    }
  }

  Future<void> syncBudgets(List<Budget> budgets) async {
    try {
      if (budgets.isNotEmpty) {
        await client
            .from('budgets')
            .upsert(budgets.map((b) => b.toSupabaseMap()).toList());
      }
    } catch (e) {
      throw Exception('Failed to sync budgets: $e');
    }
  }

  Future<void> syncExpenses(List<Expense> expenses) async {
    try {
      if (expenses.isNotEmpty) {
        await client
            .from('expenses')
            .upsert(expenses.map((e) => e.toSupabaseMap()).toList());
      }
    } catch (e) {
      throw Exception('Failed to sync expenses: $e');
    }
  }

  // Check connection
  Future<bool> isConnected() async {
    try {
      await client.from('categories').select('category_id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}
