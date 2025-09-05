import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_expense_dialog.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalBudget = provider.totalBudgetAmount;
        final totalSpent = provider.totalSpentAmount;
        final daysLeft = DateTime.now().day <= 15 ? 15 - DateTime.now().day : 30 - DateTime.now().day + 15;

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _ExpensesHeader()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _BudgetSummaryCard(spent: totalSpent, budget: totalBudget, daysLeft: daysLeft),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            const SliverToBoxAdapter(child: _QuickActionsRow()),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _SectionHeader(title: 'Recent expenses')),
            if (provider.expenses.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first expense to start tracking',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = provider.expenses[index];
                    final category = provider.getCategoryById(expense.categoryId ?? '');
                    final budget = provider.getBudgetByCategory(expense.categoryId ?? '');
                    
                    return _ExpenseListTile(
                      expense: expense,
                      category: category,
                      budget: budget,
                      onTap: () => _showEditExpenseDialog(context, expense),
                      onDelete: () => _deleteExpense(context, expense),
                    );
                  },
                  childCount: provider.expenses.length,
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
            ),
          ],
        );
      },
    );
  }

  void _showEditExpenseDialog(BuildContext context, expense) {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(expense: expense),
    );
  }

  void _deleteExpense(BuildContext context, expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense of ₱${expense.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<BudgetProvider>(context, listen: false);
              await provider.deleteExpense(expense.expenseId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted successfully!'),
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

class _ExpensesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Expense management',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _QuickActionCard(
              icon: Icons.add, 
              label: 'Add Expense',
              onTap: () => _showAddExpenseDialog(context),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _QuickActionCard(
              icon: Icons.photo_camera_outlined,
              label: 'Receipt\nScanner',
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _QuickActionCard(
              icon: Icons.description_outlined,
              label: 'Expense\nDetails',
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _QuickActionCard(
              icon: Icons.view_list_rounded,
              label: 'Expense\nList',
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, height: 1.1),
              ),
            ],
          ),
        ),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  const _ExpenseListTile({
    required this.expense,
    this.category,
    this.budget,
    this.onTap,
    this.onDelete,
  });
  final dynamic expense;
  final dynamic category;
  final dynamic budget;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryName = category?.name ?? 'Unknown';
    final categoryIcon = _getIconData(category?.iconName ?? 'category');
    // final categoryColor = Color(int.parse(category?.colorCode?.replaceFirst('#', '0xFF') ?? '0xFF4CAF50'));
    final budgetAmount = budget?.budgetAmount ?? 0.0;
    final spentAmount = budget?.spentAmount ?? 0.0;
    final isOver = budgetAmount > 0 && spentAmount > budgetAmount;
    
    final Color ringColor = isOver 
        ? Colors.red.shade600 
        : (spentAmount == budgetAmount ? Colors.black26 : Colors.green.shade600);
    
    final String trailingText = budgetAmount > 0 
        ? (isOver 
            ? '₱${(spentAmount - budgetAmount).toStringAsFixed(0)} over'
            : '₱${(budgetAmount - spentAmount).toStringAsFixed(0)} left')
        : '₱${expense.amount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          leading: _StatusRingIcon(icon: categoryIcon, color: ringColor),
          title: Text(
            expense.description ?? categoryName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${expense.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  if (budgetAmount > 0)
                    Text(
                      trailingText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isOver ? Colors.red.shade600 : Colors.black54,
                        fontSize: 12,
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
          onTap: onTap,
        ),
      ),
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
      default:
        return Icons.receipt_long;
    }
  }
}

class _StatusRingIcon extends StatelessWidget {
  const _StatusRingIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              color: Colors.white,
            ),
          ),
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F3F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 18),
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.spent,
    required this.budget,
    required this.daysLeft,
  });
  final double spent;
  final double budget;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final double ratio = (spent / budget).clamp(0, 1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Left for $daysLeft days',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₱${(budget - spent).toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade600),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Edit budget'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: ratio),
                  builder: (BuildContext context, double value, Widget? child) {
                    return Stack(
                      children: <Widget>[
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: 12,
                          width: constraints.maxWidth * value,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  '₱${spent.toStringAsFixed(0)} already spent',
                  style: const TextStyle(color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  '₱${budget.toStringAsFixed(0)} set budget',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

