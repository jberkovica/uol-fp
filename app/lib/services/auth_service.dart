import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication service using Supabase
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  /// Get the current Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    return response;
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      return true;
    } catch (e) {
      print('Google sign in error: $e');
      return false;
    }
  }

  /// Sign in with Apple OAuth  
  Future<String?> signInWithApple({
    required String idToken,
    String? nonce,
  }) async {
    try {
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: nonce,
      );
      return response.user?.id;
    } catch (e) {
      print('Apple sign in error: $e');
      return null;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get user's language preference from metadata
  String getUserLanguage() {
    final user = currentUser;
    if (user?.userMetadata != null) {
      return user!.userMetadata!['language'] as String? ?? 'en';
    }
    return 'en'; // Default to English
  }

  /// Update user's language preference in metadata
  Future<bool> updateUserLanguage(String languageCode) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Update user metadata with language preference
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...?user.userMetadata,
            'language': languageCode,
          },
        ),
      );

      return response.user != null;
    } catch (e) {
      print('Error updating user language: $e');
      return false;
    }
  }

  /// Get user's approval mode preference from metadata
  String getUserApprovalMode() {
    final user = currentUser;
    if (user?.userMetadata != null) {
      return user!.userMetadata!['approval_mode'] as String? ?? 'auto';
    }
    return 'auto'; // Default to auto-approve
  }

  /// Update user's approval mode preference in metadata
  Future<bool> updateUserApprovalMode(String approvalMode) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Validate approval mode
      if (!['auto', 'app', 'email'].contains(approvalMode)) {
        print('Invalid approval mode: $approvalMode');
        return false;
      }

      // Update user metadata with approval mode preference
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...?user.userMetadata,
            'approval_mode': approvalMode,
          },
        ),
      );

      return response.user != null;
    } catch (e) {
      print('Error updating user approval mode: $e');
      return false;
    }
  }

  /// Get user's notification preferences from metadata
  Map<String, bool> getUserNotificationPreferences() {
    final user = currentUser;
    if (user?.userMetadata != null && user!.userMetadata!.containsKey('notification_preferences')) {
      final prefs = user.userMetadata!['notification_preferences'] as Map<String, dynamic>?;
      return {
        'new_story': prefs?['new_story'] as bool? ?? true,
        'email_notifications': prefs?['email_notifications'] as bool? ?? true,
      };
    }
    return {
      'new_story': true,
      'email_notifications': true,
    };
  }

  /// Update user's notification preferences in metadata
  Future<bool> updateUserNotificationPreferences(Map<String, bool> preferences) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Update user metadata with notification preferences
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...?user.userMetadata,
            'notification_preferences': preferences,
          },
        ),
      );

      return response.user != null;
    } catch (e) {
      print('Error updating user notification preferences: $e');
      return false;
    }
  }
} 