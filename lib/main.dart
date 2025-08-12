import 'package:flutter/material.dart';

void main() {
  runApp(const BudgetsApp());
}

class BudgetsApp extends StatelessWidget {
  const BudgetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color seed = const Color(0xFF0CAF60); // fresh financial green
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budgets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
          displayColor: Colors.black87,
          bodyColor: Colors.black87,
        ),
      ),
      home: const BudgetsHomeScreen(),
    );
  }
}

class BudgetsHomeScreen extends StatefulWidget {
  const BudgetsHomeScreen({super.key});

  @override
  State<BudgetsHomeScreen> createState() => _BudgetsHomeScreenState();
}

class _BudgetsHomeScreenState extends State<BudgetsHomeScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 2; // 0: Overview, 1: Budget, 2: Expenses, 3: Insights
  int _selectedBottom = 2; // mimic the middle item as budgets

  final List<_CategoryBudget> _categories = <_CategoryBudget>[
    _CategoryBudget(
      name: 'Home',
      icon: Icons.home_filled,
      spent: 100,
      budget: 500,
    ),
    _CategoryBudget(
      name: 'Auto & Transport',
      icon: Icons.directions_car_rounded,
      spent: 236,
      budget: 180,
    ),
    _CategoryBudget(
      name: 'Education',
      icon: Icons.school_rounded,
      spent: 0,
      budget: 320,
    ),
    _CategoryBudget(
      name: 'Subscriptions',
      icon: Icons.subscriptions_rounded,
      spent: 56,
      budget: 56,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<Widget> buildSlivers() {
      if (_selectedTab == 2) {
        // Expenses view
        return <Widget>[
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
        ];
      }
      // Default to Budgets view (index 1), light placeholders for others
      return <Widget>[
        SliverToBoxAdapter(
          child: _BudgetSummaryCard(spent: 400, budget: 950, daysLeft: 14),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildCategoriesHeader(context)),
        SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            final _CategoryBudget category = _categories[index];
            return _CategoryTile(
              category: category,
              onTap:
                  () => setState(() => category.expanded = !category.expanded),
            );
          }, childCount: _categories.length),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
        ),
      ];
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _buildTopBar(context)),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildTabs(context)),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            ...buildSlivers(),
          ],
        ),
      ),
      bottomNavigationBar: _FloatingPillNav(
        selectedIndex: _selectedBottom,
        onSelected: (int i) => setState(() => _selectedBottom = i),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black12,
            child: Icon(Icons.person, color: Colors.black87),
          ),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    Widget buildChip(String label, int index) {
      final bool isSelected = _selectedTab == index;
      return GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow:
                isSelected
                    ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          buildChip('Overview', 0),
          buildChip('Budget', 1),
          buildChip('Expenses', 2),
          buildChip('Insights', 3),
        ],
      ),
    );
  }

  Widget _buildCategoriesHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Text(
            'Budget categories',
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final _CategoryBudget category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool over = category.isOver;
    final String trailingText =
        over
            ? '₱${(category.spent - category.budget).toStringAsFixed(0)} over'
            : '₱${(category.budget - category.spent).toStringAsFixed(0)} left';
    final Color trailingColor = over ? Colors.red.shade600 : Colors.black87;

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
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _CircularIconProgress(
                        icon: category.icon,
                        value: category.progress,
                        over: over,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱${category.spent.toStringAsFixed(0)} of ₱${category.budget.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: trailingColor,
                        ),
                        child: Text(trailingText),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    crossFadeState:
                        category.expanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add expense'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                    duration: const Duration(milliseconds: 220),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularIconProgress extends StatelessWidget {
  const _CircularIconProgress({
    required this.icon,
    required this.value,
    required this.over,
  });
  final IconData icon;
  final double value; // 0..∞ (will clamp visually)
  final bool over;

  @override
  Widget build(BuildContext context) {
    final Color color = over ? Colors.red.shade600 : Colors.green.shade600;
    final double clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      height: 44,
      width: 44,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: clamped),
            builder: (BuildContext context, double t, Widget? child) {
              return CircularProgressIndicator(
                value: t,
                strokeWidth: 4,
                backgroundColor: Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
          Container(
            height: 34,
            width: 34,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _FloatingPillNav extends StatelessWidget {
  const _FloatingPillNav({
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 64,
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List<Widget>.generate(4, (int i) {
              final List<IconData> icons = <IconData>[
                Icons.home_rounded,
                Icons.account_balance_wallet_rounded,
                Icons.table_chart_rounded,
                Icons.person_outline_rounded,
              ];
              return _NavItem(
                icon: icons[i],
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _CategoryBudget {
  _CategoryBudget({
    required this.name,
    required this.icon,
    required this.spent,
    required this.budget,
  });

  final String name;
  final IconData icon;
  final double spent;
  final double budget;
  bool expanded = false;

  bool get isOver => spent > budget;
  double get progress => budget == 0 ? 0 : spent / budget;
}
