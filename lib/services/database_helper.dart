import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/category.dart' as app_models;
import '../models/budget.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'epon_budget.db');
      
      print('Database path: $path');
      print('Databases directory: $databasesPath');
      
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      
      print('Database opened successfully');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');
    
    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        category_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_name TEXT,
        color_code TEXT,
        is_default INTEGER DEFAULT 0,
        created_by_user_id TEXT,
        created_at TEXT NOT NULL,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
    print('Categories table created');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        budget_id TEXT PRIMARY KEY,
        user_id TEXT,
        category_id TEXT,
        budget_name TEXT NOT NULL,
        budget_amount REAL NOT NULL,
        period_type TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        spent_amount REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        needs_sync INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
      )
    ''');
    print('Budgets table created');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        expense_id TEXT PRIMARY KEY,
        user_id TEXT,
        category_id TEXT,
        amount REAL NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        merchant_name TEXT,
        location TEXT,
        payment_method TEXT,
        receipt_img_url TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_recurring INTEGER DEFAULT 0,
        recurring_expense_id TEXT,
        needs_sync INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
      )
    ''');
    print('Expenses table created');

    // Insert default categories
    print('Inserting default categories...');
    await _insertDefaultCategories(db);
    print('Database setup complete');
  }

  Future<void> _insertDefaultCategories(Database db) async {
    // Check if categories already exist
    final existingCategories = await db.query('categories');
    if (existingCategories.isNotEmpty) {
      return; // Categories already exist, don't insert duplicates
    }
    
    final defaultCategories = [
      {
        'category_id': 'cat_food_dining',
        'name': 'Food & Dining',
        'description': 'Restaurant meals, groceries, beverages',
        'icon_name': 'restaurant',
        'color_code': '#FF6B6B',
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
      {
        'category_id': 'cat_transportation',
        'name': 'Transportation',
        'description': 'Gas, public transit, rideshare, parking',
        'icon_name': 'car',
        'color_code': '#4ECDC4',
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
      {
        'category_id': 'cat_shopping',
        'name': 'Shopping',
        'description': 'Clothing, electronics, general merchandise',
        'icon_name': 'shopping',
        'color_code': '#45B7D1',
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
      {
        'category_id': 'cat_entertainment',
        'name': 'Entertainment',
        'description': 'Movies, games, subscriptions, hobbies',
        'icon_name': 'entertainment',
        'color_code': '#96CEB4',
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
      {
        'category_id': 'cat_bills_utilities',
        'name': 'Bills & Utilities',
        'description': 'Electricity, water, internet, phone',
        'icon_name': 'bill',
        'color_code': '#FFEAA7',
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
      {
        'category_id': 'cat_healthcare',
        'name': 'Healthcare',
        'description': 'Medical expenses, pharmacy, insurance',
        'icon_name': 'medical',
        'color_code': '#DDA0DD',
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
      {
        'category_id': 'cat_education',
        'name': 'Education',
        'description': 'Books, courses, tuition, supplies',
        'icon_name': 'education',
        'color_code': '#98D8C8',
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
    ];

    for (var category in defaultCategories) {
      try {
        await db.insert('categories', category);
        print('Inserted category: ${category['name']}');
      } catch (e) {
        print('Error inserting category ${category['name']}: $e');
      }
    }
    
    // Verify categories were inserted
    final insertedCategories = await db.query('categories');
    print('Total categories after insertion: ${insertedCategories.length}');
  }

  // Category CRUD operations
  Future<int> insertCategory(app_models.Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<app_models.Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => app_models.Category.fromMap(maps[i]));
  }

  Future<app_models.Category?> getCategoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'category_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return app_models.Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(app_models.Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'category_id = ?',
      whereArgs: [category.categoryId],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'category_id = ?',
      whereArgs: [id],
    );
  }

  // Budget CRUD operations
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('budgets');
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<Budget?> getBudgetById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'budget_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'budget_id = ?',
      whereArgs: [budget.budgetId],
    );
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return await db.delete(
      'budgets',
      where: 'budget_id = ?',
      whereArgs: [id],
    );
  }

  // Expense CRUD operations
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses', orderBy: 'expense_date DESC');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<Expense?> getExpenseById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'expense_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'expense_id = ?',
      whereArgs: [expense.expenseId],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'expense_id = ?',
      whereArgs: [id],
    );
  }

  // Sync-related operations
  Future<List<Budget>> getUnsyncedBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'needs_sync = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<List<Expense>> getUnsyncedExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'needs_sync = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<app_models.Category>> getUnsyncedCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'needs_sync = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => app_models.Category.fromMap(maps[i]));
  }

  Future<void> markAsSynced(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {'needs_sync': 0},
      where: '${table.substring(0, table.length - 1)}_id = ?',
      whereArgs: [id],
    );
  }

  // Analytics queries
  Future<double> getTotalSpentAmount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalBudgetAmount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(budget_amount) as total FROM budgets WHERE is_active = 1');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.name, c.color_code, SUM(e.amount) as total_amount, COUNT(e.expense_id) as expense_count
      FROM categories c
      LEFT JOIN expenses e ON c.category_id = e.category_id
      GROUP BY c.category_id, c.name, c.color_code
      ORDER BY total_amount DESC
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
