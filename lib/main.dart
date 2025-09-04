import 'package:flutter/material.dart';
import 'screens/overview_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/insights_screen.dart';
import 'widgets/app_header.dart';
import 'widgets/bottom_navigation.dart';

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
      title: 'E-Pon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
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

class _BudgetsHomeScreenState extends State<BudgetsHomeScreen> {
  int _selectedTab = 0; // 0: Overview, 1: Insights, 2: Expenses, 3: Budgets

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const AppHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildCurrentScreen()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedTab,
        onItemSelected: (int index) => setState(() => _selectedTab = index),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedTab) {
      case 0:
        return const OverviewScreen();
      case 1:
        return const InsightsScreen();
      case 2:
        return const ExpensesScreen();
      case 3:
        return const BudgetsScreen();
      default:
        return const OverviewScreen();
    }
  }
}
