import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(child: _ExpensesHeader()),
        SliverToBoxAdapter(child: const SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: _BudgetSummaryCard(spent: 400, budget: 950, daysLeft: 14),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 12)),
        const SliverToBoxAdapter(child: _QuickActionsRow()),
        SliverToBoxAdapter(child: const SizedBox(height: 16)),
        SliverToBoxAdapter(child: _SectionHeader(title: 'Recent expenses')),
        SliverList(
          delegate: SliverChildListDelegate.fixed(<Widget>[
            _ExpenseListTile(
              name: 'Home',
              icon: Icons.home_filled,
              spent: 100,
              budget: 500,
            ),
            _ExpenseListTile(
              name: 'Auto & Transport',
              icon: Icons.directions_car_rounded,
              spent: 226,
              budget: 180,
            ),
            _ExpenseListTile(
              name: 'Education',
              icon: Icons.school_rounded,
              spent: 0,
              budget: 320,
            ),
            _ExpenseListTile(
              name: 'Subscriptions',
              icon: Icons.subscriptions_rounded,
              spent: 56,
              budget: 56,
            ),
            _ExpenseListTile(
              name: 'Auto & Transport',
              icon: Icons.directions_car_rounded,
              spent: 236,
              budget: 180,
            ),
            _ExpenseListTile(
              name: 'Subscriptions',
              icon: Icons.subscriptions_rounded,
              spent: 56,
              budget: 56,
            ),
          ]),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
        ),
      ],
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
        children: const <Widget>[
          Expanded(
            child: _QuickActionCard(icon: Icons.add, label: 'Add Expense'),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.photo_camera_outlined,
              label: 'Receipt\nScanner',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.description_outlined,
              label: 'Expense\nDetails',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.view_list_rounded,
              label: 'Expense\nList',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  const _ExpenseListTile({
    required this.name,
    required this.icon,
    required this.spent,
    required this.budget,
  });
  final String name;
  final IconData icon;
  final double spent;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final bool over = spent > budget;
    final Color ringColor =
        over
            ? Colors.red.shade600
            : (spent == budget ? Colors.black26 : Colors.green.shade600);
    final String trailingText =
        over
            ? '₱${(spent - budget).toStringAsFixed(0)} over'
            : '₱${(budget - spent).toStringAsFixed(0)} left';

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
          leading: _StatusRingIcon(icon: icon, color: ringColor),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '₱${spent.toStringAsFixed(0)} of ₱${budget.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.black54),
          ),
          trailing: Text(
            trailingText,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: over ? Colors.red.shade600 : Colors.black87,
            ),
          ),
          onTap: () {},
        ),
      ),
    );
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

