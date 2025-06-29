import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration constants
class SupabaseConfig {
  /// Supabase project URL - loaded from environment
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  
  /// Supabase anon key - loaded from environment  
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  /// Redirect URL for OAuth flows
  static const String redirectUrl = 'io.supabase.flutterquickstart://login-callback/';
  
  /// Validate that required environment variables are present
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
} 