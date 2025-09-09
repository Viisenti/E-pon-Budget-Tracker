import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:math' as math;
import '../providers/budget_provider.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/category.dart' as app_models;

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedTimeframe = 'Monthly';
  final List<String> _timeframes = ['Weekly', 'Monthly', 'Yearly'];
  
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        if (budgetProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final analytics = _calculateAnalytics(budgetProvider);

        return CustomScrollView(
          slivers: <Widget>[
            // Total Spending Overview
            SliverToBoxAdapter(child: _buildTotalSpendingSection(analytics)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Timeframe Selector
            SliverToBoxAdapter(child: _buildTimeframeSelector()),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Spending by Category (Pie Chart)
            SliverToBoxAdapter(child: _buildSpendingByCategorySection(analytics)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Top 5 Expense Categories
            SliverToBoxAdapter(child: _buildTopCategoriesSection(analytics)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Monthly Spending Trend
            SliverToBoxAdapter(child: _buildSpendingTrendSection(analytics, budgetProvider)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Budget vs Actual Comparison
            SliverToBoxAdapter(child: _buildBudgetComparisonSection(analytics)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Recurring vs One-time Expenses
            SliverToBoxAdapter(child: _buildRecurringExpensesSection(analytics)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Daily/Weekly Averages
            SliverToBoxAdapter(child: _buildAveragesSection(analytics)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Cash Flow Snapshot
            SliverToBoxAdapter(child: _buildCashFlowSection(analytics)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Financial Report Download
            SliverToBoxAdapter(child: _buildFinancialReportSection(budgetProvider, analytics)),
            
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
            ),
          ],
        );
      },
    );
  }

  AnalyticsData _calculateAnalytics(BudgetProvider provider) {
    final now = DateTime.now();
    final expenses = provider.expenses;
    final budgets = provider.budgets;
    final categories = provider.categories;

    // Filter expenses based on selected timeframe
    DateTime startDate;
    switch (_selectedTimeframe) {
      case 'Weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      default: // Monthly
        startDate = DateTime(now.year, now.month, 1);
    }

    final filteredExpenses = expenses.where((expense) => 
        expense.expenseDate.isAfter(startDate.subtract(const Duration(days: 1)))
    ).toList();

    // Calculate total spending
    final totalSpent = filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    
    // Calculate spending by category
    final categorySpending = <String, double>{};
    final categoryNames = <String, String>{};
    
    for (final expense in filteredExpenses) {
      final categoryId = expense.categoryId ?? 'uncategorized';
      categorySpending[categoryId] = (categorySpending[categoryId] ?? 0) + expense.amount;
      
      final category = categories.firstWhere(
        (cat) => cat.categoryId == categoryId,
        orElse: () => app_models.Category(
          categoryId: 'uncategorized',
          name: 'Uncategorized',
          createdAt: DateTime.now(),
        ),
      );
      categoryNames[categoryId] = category.name;
    }

    // Sort categories by spending amount
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate budget comparison
    final totalBudget = budgets.where((b) => b.isActive).fold(0.0, (sum, b) => sum + b.budgetAmount);
    final budgetProgress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;

    // Calculate recurring vs one-time expenses
    final recurringExpenses = filteredExpenses.where((e) => e.isRecurring).toList();
    final oneTimeExpenses = filteredExpenses.where((e) => !e.isRecurring).toList();
    
    final recurringTotal = recurringExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final oneTimeTotal = oneTimeExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Calculate daily/weekly averages
    final daysInPeriod = _selectedTimeframe == 'Weekly' ? 7 : 
                        _selectedTimeframe == 'Monthly' ? DateTime(now.year, now.month + 1, 0).day :
                        DateTime.now().difference(DateTime(now.year, 1, 1)).inDays + 1;
    
    final dailyAverage = totalSpent / daysInPeriod;
    final weeklyAverage = dailyAverage * 7;

    // Calculate monthly trend data
    final monthlyData = _calculateMonthlyTrend(expenses);

    return AnalyticsData(
      totalSpent: totalSpent,
      totalBudget: totalBudget,
      budgetProgress: budgetProgress,
      categorySpending: categorySpending,
      categoryNames: categoryNames,
      sortedCategories: sortedCategories,
      recurringTotal: recurringTotal,
      oneTimeTotal: oneTimeTotal,
      dailyAverage: dailyAverage,
      weeklyAverage: weeklyAverage,
      monthlyTrendData: monthlyData,
      isOverBudget: totalSpent > totalBudget,
      remainingBudget: totalBudget - totalSpent,
    );
  }

  List<MonthlyTrendData> _calculateMonthlyTrend(List<Expense> expenses) {
    final now = DateTime.now();
    final monthlyData = <int, double>{};

    // Get last 6 months of data
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      monthlyData[month.month] = 0.0;
    }

    for (final expense in expenses) {
      final month = expense.expenseDate.month;
      final year = expense.expenseDate.year;
      
      if (year == now.year && monthlyData.containsKey(month)) {
        monthlyData[month] = (monthlyData[month] ?? 0) + expense.amount;
      }
    }

    return monthlyData.entries
        .map((entry) => MonthlyTrendData(
              month: DateFormat('MMM').format(DateTime(now.year, entry.key)),
              amount: entry.value,
            ))
        .toList();
  }

  Widget _buildTotalSpendingSection(AnalyticsData analytics) {
    final progressValue = analytics.budgetProgress.clamp(0.0, 1.0);
    final progressColor = analytics.isOverBudget ? Colors.red : const Color(0xFF0CAF60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₱${_formatCurrency(analytics.totalSpent)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Total Spent',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progressValue * 100).toStringAsFixed(0)}% of budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: progressColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (analytics.isOverBudget)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Over budget by ₱${_formatCurrency(analytics.totalSpent - analytics.totalBudget)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _timeframes.map((timeframe) {
          final isSelected = timeframe == _selectedTimeframe;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeframe = timeframe;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0CAF60) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  timeframe.substring(0, 1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpendingByCategorySection(AnalyticsData analytics) {
    if (analytics.sortedCategories.isEmpty) {
      return _buildEmptyState('No spending data available');
    }

    // Take top 5 categories for pie chart
    final topCategories = analytics.sortedCategories.take(5).toList();
    final otherAmount = analytics.sortedCategories.skip(5).fold(0.0, (sum, entry) => sum + entry.value);
    
    if (otherAmount > 0) {
      topCategories.add(MapEntry('others', otherAmount));
    }

    final colors = [
      const Color(0xFF0CAF60),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF607D8B),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Spending by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
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
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: topCategories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final percentage = (data.value / analytics.totalSpent * 100);
                        
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: data.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final categoryName = data.key == 'others' 
                          ? 'Others' 
                          : analytics.categoryNames[data.key] ?? 'Unknown';
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoryName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '₱${_formatCurrency(data.value)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSection(AnalyticsData analytics) {
    if (analytics.sortedCategories.isEmpty) {
      return _buildEmptyState('No expense categories available');
    }

    final topCategories = analytics.sortedCategories.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Top 5 Expense Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
              children: topCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final categoryName = analytics.categoryNames[data.key] ?? 'Unknown';
                final percentage = (data.value / analytics.totalSpent * 100);
                
                return Padding(
                  padding: EdgeInsets.only(bottom: index < topCategories.length - 1 ? 16 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0CAF60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0CAF60),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₱${_formatCurrency(data.value)} • ${percentage.toStringAsFixed(1)}% of total expenses',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendSection(AnalyticsData analytics, BudgetProvider provider) {
    if (analytics.monthlyTrendData.isEmpty) {
      return _buildEmptyState('No trend data available');
    }

    final maxY = analytics.monthlyTrendData.map((e) => e.amount).reduce(math.max);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3. Monthly Spending Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(20),
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < analytics.monthlyTrendData.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              analytics.monthlyTrendData[index].month,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      reservedSize: 60,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '₱${_formatCurrency(value)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                minX: 0,
                maxX: analytics.monthlyTrendData.length.toDouble() - 1,
                minY: 0,
                maxY: maxY * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: analytics.monthlyTrendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.amount);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0CAF60),
                        const Color(0xFF0CAF60).withOpacity(0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF0CAF60),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0CAF60).withOpacity(0.3),
                          const Color(0xFF0CAF60).withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetComparisonSection(AnalyticsData analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '4. Comparison to Budget',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '${(analytics.budgetProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: analytics.isOverBudget ? Colors.red : const Color(0xFF0CAF60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: analytics.budgetProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    analytics.isOverBudget ? Colors.red : const Color(0xFF0CAF60),
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Budget',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '₱${_formatCurrency(analytics.totalBudget)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          analytics.isOverBudget ? 'Over Budget' : 'Remaining',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '₱${_formatCurrency(analytics.remainingBudget.abs())}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: analytics.isOverBudget ? Colors.red : const Color(0xFF0CAF60),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (analytics.budgetProgress >= 0.8)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: analytics.isOverBudget 
                          ? Colors.red.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          analytics.isOverBudget ? Icons.error : Icons.warning,
                          color: analytics.isOverBudget ? Colors.red : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            analytics.isOverBudget
                                ? 'You\'ve exceeded your budget. Consider reviewing your expenses.'
                                : 'You\'ve spent ${(analytics.budgetProgress * 100).toStringAsFixed(0)}% of your budget this ${_selectedTimeframe.toLowerCase()}.',
                            style: TextStyle(
                              fontSize: 12,
                              color: analytics.isOverBudget ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringExpensesSection(AnalyticsData analytics) {
    final total = analytics.recurringTotal + analytics.oneTimeTotal;
    final recurringPercentage = total > 0 ? (analytics.recurringTotal / total * 100) : 0;
    final oneTimePercentage = total > 0 ? (analytics.oneTimeTotal / total * 100) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '5. Recurring vs. One-Time Expenses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
                _buildExpenseTypeRow(
                  'Recurring Expenses',
                  analytics.recurringTotal,
                  recurringPercentage,
                  const Color(0xFF0CAF60),
                ),
                const SizedBox(height: 16),
                _buildExpenseTypeRow(
                  'One-Time Expenses',
                  analytics.oneTimeTotal,
                  oneTimePercentage,
                  const Color(0xFF2196F3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTypeRow(String title, double amount, double percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₱${_formatCurrency(amount)} • ${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAveragesSection(AnalyticsData analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6. Daily/Weekly Averages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                        Icons.today,
                        color: const Color(0xFF0CAF60),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₱${_formatCurrency(analytics.dailyAverage)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Daily Average',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                        Icons.date_range,
                        color: const Color(0xFF2196F3),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₱${_formatCurrency(analytics.weeklyAverage)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Weekly Average',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowSection(AnalyticsData analytics) {
    // For simplicity, assuming a fixed income. In a real app, this would come from user input
    const monthlyIncome = 50000.0; // This should be configurable by the user
    final surplus = monthlyIncome - analytics.totalSpent;
    final isSurplus = surplus > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '8. Cash Flow Snapshot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '₱${_formatCurrency(monthlyIncome)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0CAF60),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '₱${_formatCurrency(analytics.totalSpent)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSurplus ? 'Remaining Balance' : 'Deficit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '₱${_formatCurrency(surplus.abs())}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSurplus ? const Color(0xFF0CAF60) : Colors.red,
                      ),
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

  Widget _buildFinancialReportSection(BudgetProvider provider, AnalyticsData analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0CAF60).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.file_download,
                        color: Color(0xFF0CAF60),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download Monthly Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Get detailed PDF report of your finances',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _generatePDFReport(provider, analytics),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0CAF60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Generate PDF Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(40),
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
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePDFReport(BudgetProvider provider, AnalyticsData analytics) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('MMMM yyyy');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Financial Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${dateFormat.format(now)} • E-pon Budget Tracker',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),

              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Financial Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Budget:'),
                        pw.Text('₱${_formatCurrency(analytics.totalBudget)}'),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Spent:'),
                        pw.Text('₱${_formatCurrency(analytics.totalSpent)}'),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Remaining:'),
                        pw.Text(
                          '₱${_formatCurrency(analytics.remainingBudget)}',
                          style: pw.TextStyle(
                            color: analytics.isOverBudget ? PdfColors.red : PdfColors.green,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Top Categories Section
              pw.Text(
                'Top Expense Categories',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Percentage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...analytics.sortedCategories.take(10).map((entry) {
                    final categoryName = analytics.categoryNames[entry.key] ?? 'Unknown';
                    final percentage = (entry.value / analytics.totalSpent * 100);
                    
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(categoryName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('₱${_formatCurrency(entry.value)}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${percentage.toStringAsFixed(1)}%'),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              // Averages Section
              pw.Text(
                'Spending Averages',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Daily Average'),
                      pw.Text(
                        '₱${_formatCurrency(analytics.dailyAverage)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Weekly Average'),
                      pw.Text(
                        '₱${_formatCurrency(analytics.weeklyAverage)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Text(
                'Generated on ${DateFormat('MMMM dd, yyyy at HH:mm').format(now)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ];
          },
        ),
      );

      // Save and share the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/financial_report_${DateFormat('yyyy_MM').format(now)}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Financial Report for ${dateFormat.format(now)}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Financial report generated and ready to share!'),
            backgroundColor: Color(0xFF0CAF60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }
}

// Data classes for analytics
class AnalyticsData {
  final double totalSpent;
  final double totalBudget;
  final double budgetProgress;
  final Map<String, double> categorySpending;
  final Map<String, String> categoryNames;
  final List<MapEntry<String, double>> sortedCategories;
  final double recurringTotal;
  final double oneTimeTotal;
  final double dailyAverage;
  final double weeklyAverage;
  final List<MonthlyTrendData> monthlyTrendData;
  final bool isOverBudget;
  final double remainingBudget;

  AnalyticsData({
    required this.totalSpent,
    required this.totalBudget,
    required this.budgetProgress,
    required this.categorySpending,
    required this.categoryNames,
    required this.sortedCategories,
    required this.recurringTotal,
    required this.oneTimeTotal,
    required this.dailyAverage,
    required this.weeklyAverage,
    required this.monthlyTrendData,
    required this.isOverBudget,
    required this.remainingBudget,
  });
}

class MonthlyTrendData {
  final String month;
  final double amount;

  MonthlyTrendData({
    required this.month,
    required this.amount,
  });
}

