import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'auth_service.dart';
import 'app_state_service.dart';

/// Service to manage app language state and persistence
/// Following best practices: Server as single source of truth with local caching
class LanguageService extends ChangeNotifier {
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  LanguageService._();

  Locale _currentLocale = const Locale('en');
  String _currentLanguageCode = 'en';
  bool _isInitialized = false;
  
  /// Get current locale for UI
  Locale get currentLocale => _currentLocale;
  
  /// Get current language code for API calls - single source of truth
  String get currentLanguageCode => _currentLanguageCode;
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize language service with clean priority logic
  /// Best practice: Server (Supabase) is source of truth, local is cache
  Future<void> initialize() async {
    try {
      String detectedLanguage = 'en';
      
      // For authenticated users: Server is source of truth
      if (AuthService.instance.isAuthenticated) {
        // Wait briefly for auth to stabilize
        await Future.delayed(const Duration(milliseconds: 100));
        
        final user = AuthService.instance.currentUser;
        if (user?.userMetadata != null && user!.userMetadata!.containsKey('language')) {
          // User has explicit language preference in server
          detectedLanguage = user.userMetadata!['language'] as String? ?? 'en';
          
          // Sync to local cache
          await AppStateService.saveLanguage(detectedLanguage);
          
          print('[LanguageService] Initialized from server: $detectedLanguage');
        } else {
          // Authenticated but no server preference - check local cache
          detectedLanguage = await _initializeFromLocalOrSystem();
          
          // Sync to server for future consistency
          await AuthService.instance.updateUserLanguage(detectedLanguage);
        }
      } else {
        // Not authenticated - use local cache or system detection
        detectedLanguage = await _initializeFromLocalOrSystem();
      }
      
      // Apply the detected language
      _applyLanguage(detectedLanguage);
      _isInitialized = true;
      
    } catch (e) {
      print('[LanguageService] Initialization error: $e');
      // Fallback to English on any error
      _applyLanguage('en');
      _isInitialized = true;
    }
  }
  
  /// Initialize from local cache or system language
  Future<String> _initializeFromLocalOrSystem() async {
    // Check local cache first
    final cachedLanguage = AppStateService.getLanguage();
    if (cachedLanguage != null && isSupported(cachedLanguage)) {
      print('[LanguageService] Initialized from cache: $cachedLanguage');
      return cachedLanguage;
    }
    
    // Fall back to system language detection
    final systemLocale = ui.window.locale;
    final systemLanguageCode = systemLocale.languageCode;
    
    if (isSupported(systemLanguageCode)) {
      await AppStateService.saveLanguage(systemLanguageCode);
      print('[LanguageService] Initialized from system: $systemLanguageCode');
      return systemLanguageCode;
    }
    
    // Default to English
    await AppStateService.saveLanguage('en');
    print('[LanguageService] Initialized with default: en');
    return 'en';
  }
  
  /// Apply language to both locale and language code
  void _applyLanguage(String languageCode) {
    _currentLanguageCode = languageCode;
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  /// Update app language - best practice implementation
  /// Updates all stores: memory, local cache, and server
  Future<bool> updateLanguage(String languageCode) async {
    try {
      // Validate language code
      if (!isSupported(languageCode)) {
        print('[LanguageService] Unsupported language code: $languageCode');
        return false;
      }
      
      // Apply immediately for responsive UI
      _applyLanguage(languageCode);
      
      // Save to local cache (works offline)
      await AppStateService.saveLanguage(languageCode);
      print('[LanguageService] Language updated locally: $languageCode');
      
      // Sync to server if authenticated
      if (AuthService.instance.isAuthenticated) {
        final success = await AuthService.instance.updateUserLanguage(languageCode);
        if (success) {
          print('[LanguageService] Language synced to server: $languageCode');
        } else {
          print('[LanguageService] Warning: Server sync failed, but local update preserved');
        }
      }
      
      return true;
    } catch (e) {
      print('[LanguageService] Error updating language: $e');
      return false;
    }
  }
  
  /// Sync language from server - used when auth state changes
  Future<void> syncFromServer() async {
    if (!AuthService.instance.isAuthenticated) return;
    
    try {
      final user = AuthService.instance.currentUser;
      if (user?.userMetadata != null && user!.userMetadata!.containsKey('language')) {
        final serverLanguage = user.userMetadata!['language'] as String;
        
        if (serverLanguage != _currentLanguageCode && isSupported(serverLanguage)) {
          print('[LanguageService] Syncing language from server: $serverLanguage');
          _applyLanguage(serverLanguage);
          await AppStateService.saveLanguage(serverLanguage);
        }
      }
    } catch (e) {
      print('[LanguageService] Error syncing from server: $e');
    }
  }

  /// Get supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ru'), // Russian
    Locale('lv'), // Latvian
  ];

  /// Check if locale is supported
  static bool isSupported(String languageCode) {
    return supportedLocales.any((locale) => locale.languageCode == languageCode);
  }
}