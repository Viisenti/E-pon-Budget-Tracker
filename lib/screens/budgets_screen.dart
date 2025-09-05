import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_budget_dialog.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _BudgetSummarySection()),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _BudgetCategoriesSection()),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetSummarySection extends StatelessWidget {
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
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: remaining < 0 ? Colors.red : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₱${totalSpent.toStringAsFixed(0)} already spent',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  totalSpent > totalBudget ? Colors.red : const Color(0xFF0CAF60),
                                ),
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showAddBudgetDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0CAF60),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Add budget',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₱${totalBudget.toStringAsFixed(0)} total budget',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddBudgetDialog(),
    );
  }
}

class _BudgetCategoriesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final budgets = provider.budgets.where((b) => b.isActive).toList();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Budget categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                ],
              ),
              const SizedBox(height: 16),
              if (budgets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No budgets yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first budget to start tracking your expenses',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: budgets.map((budget) {
                      final category = provider.getCategoryById(budget.categoryId ?? '');
                      final iconData = _getIconData(category?.iconName ?? 'home');
                      final color = Color(int.parse(category?.colorCode?.replaceFirst('#', '0xFF') ?? '0xFF4CAF50'));
                      
                      return _BudgetCategoryTile(
                        budget: budget,
                        category: category,
                        icon: iconData,
                        title: budget.budgetName,
                        spent: budget.spentAmount,
                        budgetAmount: budget.budgetAmount,
                        color: color,
                        isOverBudget: budget.isOverBudget,
                        onTap: () => _showEditBudgetDialog(context, budget),
                        onDelete: () => _deleteBudget(context, budget),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
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
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'school':
        return Icons.school;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'flash_on':
        return Icons.flash_on;
      default:
        return Icons.category;
    }
  }

  void _showEditBudgetDialog(BuildContext context, budget) {
    showDialog(
      context: context,
      builder: (context) => AddBudgetDialog(budget: budget),
    );
  }

  void _deleteBudget(BuildContext context, budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete "${budget.budgetName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<BudgetProvider>(context, listen: false);
              await provider.deleteBudget(budget.budgetId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Budget deleted successfully!'),
                  backgroundColor: Color(0xFF0CAF60),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  final dynamic budget;
  final dynamic category;
  final IconData icon;
  final String title;
  final double spent;
  final double budgetAmount;
  final Color color;
  final bool isOverBudget;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _BudgetCategoryTile({
    required this.budget,
    this.category,
    required this.icon,
    required this.title,
    required this.spent,
    required this.budgetAmount,
    required this.color,
    this.isOverBudget = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = budgetAmount - spent;
    final progress = budgetAmount > 0 ? spent / budgetAmount : 0.0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isOverBudget
                        ? Colors.red.withOpacity(0.1)
                        : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    isOverBudget ? Border.all(color: Colors.red, width: 1) : null,
              ),
              child: Icon(
                icon,
                color: isOverBudget ? Colors.red : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${spent.toStringAsFixed(0)} of ₱${budgetAmount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isOverBudget
                      ? '₱${(spent - budgetAmount).toStringAsFixed(0)} over'
                      : '₱${remaining.toStringAsFixed(0)} left',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOverBudget ? Colors.red : const Color(0xFF0CAF60),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: progress > 1 ? 1 : progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? Colors.red : const Color(0xFF0CAF60),
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: Colors.grey[600], size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
