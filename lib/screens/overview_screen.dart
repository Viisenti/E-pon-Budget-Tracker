import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_expense_bottom_sheet.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _OverviewHeader()),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _BudgetSummaryCard()),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _QuickActionsSection()),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _RecentTransactionsSection()),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, Algerard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final totalBudget = provider.totalBudgetAmount;
        final totalSpent = provider.totalSpentAmount;
        final remaining = totalBudget - totalSpent;
        final daysLeft = DateTime.now().day <= 15 ? 15 - DateTime.now().day : 30 - DateTime.now().day + 15;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Left for $daysLeft days',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${remaining.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: remaining < 0 ? Colors.red : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Budget',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₱${totalBudget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Spent',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₱${totalSpent.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories.take(8).toList();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (categories.length >= 4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: categories.take(4).map((category) {
                    return _QuickActionItem(
                      icon: _getIconData(category.iconName ?? 'category'),
                      label: category.name,
                      color: Color(int.parse(category.colorCode?.replaceFirst('#', '0xFF') ?? '0xFF0CAF60')),
                      onTap: () => _showAddExpenseDialog(context, category.categoryId),
                    );
                  }).toList(),
                ),
              if (categories.length > 4) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: categories.skip(4).take(4).map((category) {
                    return _QuickActionItem(
                      icon: _getIconData(category.iconName ?? 'category'),
                      label: category.name,
                      color: Color(int.parse(category.colorCode?.replaceFirst('#', '0xFF') ?? '0xFF0CAF60')),
                      onTap: () => _showAddExpenseDialog(context, category.categoryId),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, String? categoryId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseBottomSheet(preselectedCategoryId: categoryId),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      // New category icons
      case 'restaurant':
        return Icons.restaurant;
      case 'car':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bill':
        return Icons.receipt_long;
      case 'medical':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      // Legacy icons for backward compatibility
      case 'home':
        return Icons.home_filled;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'subscriptions':
        return Icons.subscriptions_rounded;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'flash_on':
        return Icons.flash_on;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'sports_esports':
        return Icons.sports_esports;
      default:
        return Icons.category;
    }
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final recentExpenses = provider.expenses.take(5).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Navigate to expenses screen
                      DefaultTabController.of(context)?.animateTo(2);
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentExpenses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add your first expense to get started',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentExpenses.map((expense) {
                  final category = provider.getCategoryById(expense.categoryId ?? '');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TransactionTile(
                      expense: expense,
                      category: category,
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic expense;
  final dynamic category;

  const _TransactionTile({
    required this.expense,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = category?.name ?? 'Unknown';
    final description = expense.description?.isNotEmpty == true ? expense.description : categoryName;
    final date = expense.expenseDate;
    final dateString = '${date.day}/${date.month}/${date.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(int.parse(category?.colorCode?.replaceFirst('#', '0xFF') ?? '0xFF4CAF50')).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(category?.iconName ?? 'receipt_long'),
              color: Color(int.parse(category?.colorCode?.replaceFirst('#', '0xFF') ?? '0xFF4CAF50')),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$categoryName • $dateString',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '₱${expense.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home_filled;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'subscriptions':
        return Icons.subscriptions_rounded;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'flash_on':
        return Icons.flash_on;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'sports_esports':
        return Icons.sports_esports;
      default:
        return Icons.receipt_long;
    }
  }
}
