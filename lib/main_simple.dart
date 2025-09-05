import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/budget_provider.dart';
import 'widgets/bottom_navigation.dart';
import 'widgets/app_header.dart';
import 'screens/overview_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/budgets_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://wasrcfohojjdaqzrkojh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indhc3JjZm9ob2pqZGFxenJrb2poIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY4NjY5NzAsImV4cCI6MjA1MjQ0Mjk3MH0.qgzgJhVZJgxqnRvKGLGGFYlMPsxqJMJdZbNKGVJgJgY',
  );
  
  runApp(const BudgetsApp());
}

class BudgetsApp extends StatelessWidget {
  const BudgetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color seed = const Color(0xFF0CAF60);
    return ChangeNotifierProvider(
      create: (context) => BudgetProvider()..initialize(),
      child: MaterialApp(
        title: 'E-Pon',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          textTheme: Theme.of(context).textTheme.apply(displayColor: Colors.black87, bodyColor: Colors.black87),
        ),
        home: const BudgetsHomeScreen(),
      ),
    );
  }
}

class BudgetsHomeScreen extends StatefulWidget {
  const BudgetsHomeScreen({super.key});

  @override
  State<BudgetsHomeScreen> createState() => _BudgetsHomeScreenState();
}

class _BudgetsHomeScreenState extends State<BudgetsHomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AppHeader(),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            OverviewScreen(),
            InsightsScreen(),
            ExpensesScreen(),
            BudgetsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigation(
          tabController: _tabController,
        ),
      ),
    );
  }
}
