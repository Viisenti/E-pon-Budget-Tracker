import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_auth_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'main.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  bool _isLoading = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authService.authStateChanges.listen((AuthState state) {
      if (mounted) {
        _determineInitialScreen();
      }
    });
  }

  Future<void> _determineInitialScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_authService.isAuthenticated) {
        // User is authenticated, check onboarding status
        final isOnboardingCompleted = await _authService.isOnboardingCompleted();
        
        if (isOnboardingCompleted) {
          // Go to main app
          setState(() {
            _initialScreen = const BudgetsHomeScreen();
            _isLoading = false;
          });
        } else {
          // Go to onboarding
          setState(() {
            _initialScreen = const OnboardingFlow();
            _isLoading = false;
          });
        }
      } else {
        // User is not authenticated, show welcome screen
        setState(() {
          _initialScreen = const WelcomeScreen();
          _isLoading = false;
        });
      }
    } catch (e) {
      // On error, show welcome screen
      setState(() {
        _initialScreen = const WelcomeScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'E-Pon',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _initialScreen ?? const WelcomeScreen();
  }
}
