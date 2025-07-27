import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Uncomment when Google Sign-In is configured
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'logging_service.dart';

/// Authentication service using Supabase
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();
  
  static final _logger = LoggingService.getLogger('AuthService');

  /// Get the current Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // TODO: Complete Google Sign-In setup for web
  // 1. Add Google OAuth client ID to web/index.html: <meta name="google-signin-client_id" content="YOUR_CLIENT_ID" />
  // 2. Configure Google Sign-In in Google Cloud Console
  // 3. Uncomment the code below:
  
  /*
  /// Google Sign In instance (lazy initialization)
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get _googleSignInInstance {
    return _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }
  */

  /// Initialize OAuth listener for Supabase redirects
  void initializeOAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      // Handle auth state changes for OAuth flows
      if (data.event == AuthChangeEvent.signedIn) {
        // OAuth sign-in successful
        _logger.i('OAuth sign-in successful'); // User email not logged for privacy
      }
    });
  }

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
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Web platform uses Supabase OAuth directly
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${Uri.base.origin}/auth/callback',
        );
        // On web, OAuth happens via redirect, so we return null
        // The actual auth response will come through the auth state listener
        return null;
      }
      
      // TODO: Uncomment when Google Sign-In setup is complete
      throw Exception('Google Sign-In not configured yet');
      /*
      // Mobile platforms use Google Sign In plugin
      final GoogleSignInAccount? googleUser = await _googleSignInInstance.signIn();
      if (googleUser == null) return null; // User cancelled
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google credentials');
      }
      
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      return response;
      */
    } catch (e) {
      _logger.e('Google sign in error', error: e);
      return null;
    }
  }

  /// Sign in with Apple OAuth  
  Future<AuthResponse?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS) {
        throw Exception('Apple Sign In is only available on iOS, macOS, and Web');
      }

      // Web platform uses Supabase OAuth directly
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: '${Uri.base.origin}/auth/callback',
        );
        // On web, OAuth happens via redirect, so we return null
        return null;
      }

      // Check if Apple Sign In is available on device
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      // Request Apple Sign In credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        throw Exception('Failed to get Apple ID token');
      }

      // Sign in with Supabase using Apple credentials
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: credential.authorizationCode,
      );

      return response;
    } catch (e) {
      _logger.e('Apple sign in error', error: e);
      return null;
    }
  }

  /// Sign in with Facebook OAuth
  Future<AuthResponse?> signInWithFacebook() async {
    try {
      // Web platform uses Supabase OAuth directly
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.facebook,
          redirectTo: '${Uri.base.origin}/auth/callback',
        );
        // On web, OAuth happens via redirect, so we return null
        return null;
      }

      // Mobile platforms use Facebook Auth plugin
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed: ${result.status}');
      }

      final AccessToken accessToken = result.accessToken!;
      
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken.tokenString,
      );

      return response;
    } catch (e) {
      _logger.e('Facebook sign in error', error: e);
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
      _logger.e('Error updating user language', error: e);
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
        _logger.w('Invalid approval mode: $approvalMode');
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
      _logger.e('Error updating user approval mode', error: e);
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
      _logger.e('Error updating user notification preferences', error: e);
      return false;
    }
  }
} 