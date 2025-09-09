import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // Get current user ID
  String? get currentUserId => client.auth.currentUser?.id;

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.epon://login-callback',
      );
      
      // Wait for auth state change
      await for (final AuthState state in client.auth.onAuthStateChange) {
        if (state.event == AuthChangeEvent.signedIn && state.session?.user != null) {
          await _createUserProfile(state.session!.user);
          return true;
        }
        if (state.event == AuthChangeEvent.signedOut) {
          return false;
        }
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Create or update user profile in database
  Future<void> _createUserProfile(User user) async {
    try {
      final existingUser = await client
          .from('users')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        // Create new user profile
        await client.from('users').insert({
          'user_id': user.id,
          'email': user.email,
          'first_name': user.userMetadata?['full_name']?.toString().split(' ').first ?? '',
          'last_name': user.userMetadata?['full_name']?.toString().split(' ').skip(1).join(' ') ?? '',
          'profile_pic_url': user.userMetadata?['avatar_url'],
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Create default user preferences
        await _createDefaultUserPreferences(user.id);
        
        // Create default categories for the user
        await _createDefaultCategories(user.id);
      } else {
        // Update existing user profile
        await client.from('users').update({
          'updated_at': DateTime.now().toIso8601String(),
          'is_active': true,
        }).eq('user_id', user.id);
      }
    } catch (e) {
      print('Error creating/updating user profile: $e');
      // Don't throw here as authentication was successful
    }
  }

  // Create default user preferences
  Future<void> _createDefaultUserPreferences(String userId) async {
    try {
      await client.from('user_preferences').insert({
        'user_id': userId,
        'currency': 'USD',
        'date_format': 'MM/DD/YYYY',
        'notifications_enabled': true,
        'budget_alert_settings': {
          'enabled': true,
          'threshold_percentage': 80,
          'frequency': 'daily'
        },
        'category_preferences': {},
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating default user preferences: $e');
    }
  }

  // Create default categories for new user
  Future<void> _createDefaultCategories(String userId) async {
    try {
      final defaultCategories = [
        {
          'name': 'Food & Dining',
          'description': 'Restaurants, groceries, and food delivery',
          'icon_name': 'restaurant',
          'color_code': '#FF6B6B',
          'is_default': true,
          'created_by_user_id': userId,
        },
        {
          'name': 'Transportation',
          'description': 'Gas, public transport, rideshare, parking',
          'icon_name': 'directions_car',
          'color_code': '#4ECDC4',
          'is_default': true,
          'created_by_user_id': userId,
        },
        {
          'name': 'Shopping',
          'description': 'Clothing, electronics, and general shopping',
          'icon_name': 'shopping_bag',
          'color_code': '#45B7D1',
          'is_default': true,
          'created_by_user_id': userId,
        },
        {
          'name': 'Entertainment',
          'description': 'Movies, games, subscriptions, hobbies',
          'icon_name': 'movie',
          'color_code': '#96CEB4',
          'is_default': true,
          'created_by_user_id': userId,
        },
        {
          'name': 'Bills & Utilities',
          'description': 'Rent, electricity, water, internet, phone',
          'icon_name': 'receipt_long',
          'color_code': '#FECA57',
          'is_default': true,
          'created_by_user_id': userId,
        },
        {
          'name': 'Healthcare',
          'description': 'Medical expenses, pharmacy, insurance',
          'icon_name': 'local_hospital',
          'color_code': '#FF9FF3',
          'is_default': true,
          'created_by_user_id': userId,
        },
        {
          'name': 'Education',
          'description': 'Books, courses, tuition, learning materials',
          'icon_name': 'school',
          'color_code': '#54A0FF',
          'is_default': true,
          'created_by_user_id': userId,
        },
        {
          'name': 'Personal Care',
          'description': 'Haircuts, cosmetics, gym, wellness',
          'icon_name': 'spa',
          'color_code': '#5F27CD',
          'is_default': true,
          'created_by_user_id': userId,
        },
      ];

      for (final category in defaultCategories) {
        await client.from('categories').insert(category);
      }
    } catch (e) {
      print('Error creating default categories: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      
      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Check onboarding completion status
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  // Mark onboarding as completed
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await client
          .from('users')
          .select()
          .eq('user_id', currentUserId!)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? phoneNumber,
  }) async {
    if (!isAuthenticated) return;

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      await client
          .from('users')
          .update(updates)
          .eq('user_id', currentUserId!);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
