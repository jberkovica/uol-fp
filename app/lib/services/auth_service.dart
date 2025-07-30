import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Uncomment when Google Sign-In is configured
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'logging_service.dart';

/// Registration completion status
enum RegistrationStatus {
  notLoggedIn,
  emailNotVerified,
  pinNotSet,
  complete,
}

/// Authentication service using Supabase
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();
  
  static final _logger = LoggingService.getLogger('AuthService');

  /// Get the current Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Session management - only for web
  DateTime? _lastActivity;
  static const Duration _sessionTimeout = Duration(days: 7); // 7 days for web only
  bool _isSessionExpired = false;

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


  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null && !_isSessionExpired;
  
  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;
  
  /// Check if session is expired
  bool get isSessionExpired => _isSessionExpired;

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

  /// Sign up with email and password (sends OTP for verification)
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _logger.i('Attempting OTP-based signup');
    
    // Use signInWithOtp for proper OTP flow during signup
    // Note: Email template must be configured to use {{ .Token }} instead of {{ .ConfirmationURL }}
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      data: fullName != null ? {'full_name': fullName, 'password': password} : {'password': password},
    );
    
    _logger.i('OTP sent for email verification during signup');
    
    // Return empty response - actual user creation happens during OTP verification
    return AuthResponse(
      user: null,
      session: null,
    );
  }

  /// Verify email with OTP code
  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email, // Use 'email' type for signInWithOtp verification
    );
    return response;
  }

  /// Resend OTP code for email verification
  Future<void> resendEmailOTP({
    required String email,
  }) async {
    // Resend using signInWithOtp again
    // Note: For existing signup flows, we still need shouldCreateUser: true
    // because the user might not be fully created yet during OTP verification
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  /// Update user's password after OTP verification
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
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
    try {
      await _supabase.auth.signOut();
      _clearSessionData();
      _logger.i('User signed out successfully');
    } catch (e, stackTrace) {
      _logger.e('Sign out error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Update last activity timestamp
  void updateActivity() {
    _lastActivity = DateTime.now();
    _isSessionExpired = false;
  }
  
  /// Validate current session
  Future<bool> validateSession() async {
    if (currentUser == null) {
      _isSessionExpired = true;
      return false;
    }
    
    // Only check session timeout on web platform
    if (kIsWeb && _lastActivity != null) {
      final timeSinceActivity = DateTime.now().difference(_lastActivity!);
      if (timeSinceActivity > _sessionTimeout) {
        _logger.w('Web session expired due to inactivity (7 days)');
        _isSessionExpired = true;
        await signOut();
        return false;
      }
    }
    
    // Check if session is still valid with Supabase
    try {
      final session = currentSession;
      if (session != null) {
        // Refresh session if it's close to expiring
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
        final timeUntilExpiry = expiresAt.difference(DateTime.now());
        
        if (timeUntilExpiry.inMinutes < 30) {
          _logger.i('Refreshing session token');
          await _supabase.auth.refreshSession();
        }
        
        updateActivity();
        return true;
      } else {
        _isSessionExpired = true;
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Session validation failed', error: e, stackTrace: stackTrace);
      _isSessionExpired = true;
      await signOut();
      return false;
    }
  }
  
  /// Clear session data
  void _clearSessionData() {
    _lastActivity = null;
    _isSessionExpired = false;
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

  /// Get user's parent PIN from metadata
  String? getParentPin() {
    final user = currentUser;
    if (user?.userMetadata != null) {
      return user!.userMetadata!['parent_pin'] as String?;
    }
    return null;
  }

  /// Check if user has set a parent PIN
  bool hasParentPin() {
    return getParentPin() != null;
  }

  /// Get the user's registration completion status
  /// Returns the next step needed to complete registration
  RegistrationStatus getRegistrationStatus() {
    if (!isAuthenticated) {
      return RegistrationStatus.notLoggedIn;
    }
    
    final user = currentUser;
    
    // Check if email is confirmed
    if (user?.emailConfirmedAt == null) {
      return RegistrationStatus.emailNotVerified;
    }
    
    // Check if PIN is set up
    if (!hasParentPin()) {
      return RegistrationStatus.pinNotSet;
    }
    
    return RegistrationStatus.complete;
  }

  /// Update user's parent PIN in metadata
  Future<bool> updateParentPin(String newPin) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Basic PIN validation (4 digits)
      if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
        _logger.w('Invalid PIN format: must be 4 digits');
        return false;
      }

      // Update user metadata with parent PIN
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...?user.userMetadata,
            'parent_pin': newPin,
          },
        ),
      );

      return response.user != null;
    } catch (e) {
      _logger.e('Error updating parent PIN', error: e);
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