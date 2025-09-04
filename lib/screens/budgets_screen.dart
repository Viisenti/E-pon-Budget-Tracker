import 'package:flutter/material.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}

class _BudgetSummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Left for 14 days',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱500',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
                            '₱400 already spent',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.42, // 400/950
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF0CAF60),
                            ),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0CAF60),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Edit budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₱950 set budget',
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
  }
}

class _BudgetCategoriesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              children: [
                _BudgetCategoryTile(
                  icon: Icons.home,
                  title: 'Home',
                  spent: 100,
                  budget: 500,
                  color: const Color(0xFF4CAF50),
                ),
                _BudgetCategoryTile(
                  icon: Icons.directions_car,
                  title: 'Auto & Transport',
                  spent: 236,
                  budget: 180,
                  color: Colors.red,
                  isOverBudget: true,
                ),
                _BudgetCategoryTile(
                  icon: Icons.school,
                  title: 'Education',
                  spent: 0,
                  budget: 320,
                  color: const Color(0xFF2196F3),
                ),
                _BudgetCategoryTile(
                  icon: Icons.calendar_today,
                  title: 'Subscriptions',
                  spent: 5,
                  budget: 61,
                  color: const Color(0xFFFF9800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double spent;
  final double budget;
  final Color color;
  final bool isOverBudget;

  const _BudgetCategoryTile({
    required this.icon,
    required this.title,
    required this.spent,
    required this.budget,
    required this.color,
    this.isOverBudget = false,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = budget - spent;
    final progress = spent / budget;

    return Padding(
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
                  '₱${spent.toInt()} of ₱${budget.toInt()}',
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
                    ? '₱${(spent - budget).toInt()} over'
                    : '₱${remaining.toInt()} left',
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
        ],
      ),
    );
  }
}
