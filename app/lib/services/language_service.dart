import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'auth_service.dart';
import 'app_state_service.dart';

/// Service to manage app language state and persistence
class LanguageService extends ChangeNotifier {
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  LanguageService._();

  Locale _currentLocale = const Locale('en');
  
  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Initialize language service
  /// Priority: 1) User explicit choice (auth metadata != default), 2) Local storage, 3) System language, 4) Default English
  Future<void> initialize() async {
    String? languageCode;
    
    // 1. Check if user has explicitly chosen a language (not just default)
    if (AuthService.instance.isAuthenticated) {
      languageCode = AuthService.instance.getUserLanguage();
      // Only use auth metadata if it's been explicitly set (has metadata key)
      final user = AuthService.instance.currentUser;
      if (user?.userMetadata != null && user!.userMetadata!.containsKey('language')) {
        _currentLocale = Locale(languageCode);
        notifyListeners();
        return;
      }
    }
    
    // 2. Check local storage for previously saved preference
    final savedLanguage = AppStateService.getLanguage();
    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
      return;
    }
    
    // 3. Detect system language for first-time users
    final systemLocale = ui.window.locale;
    final systemLanguageCode = systemLocale.languageCode;
    
    // Use system language if supported, otherwise default to English
    if (isSupported(systemLanguageCode)) {
      _currentLocale = Locale(systemLanguageCode);
      // Save system language as initial preference
      await AppStateService.saveLanguage(systemLanguageCode);
    } else {
      _currentLocale = const Locale('en');
      await AppStateService.saveLanguage('en');
    }
    
    notifyListeners();
  }

  /// Update app language
  Future<bool> updateLanguage(String languageCode) async {
    try {
      // Update locale immediately for UI responsiveness
      _currentLocale = Locale(languageCode);
      notifyListeners();

      // Save to local storage for offline access
      await AppStateService.saveLanguage(languageCode);

      // Save to user metadata if authenticated
      if (AuthService.instance.isAuthenticated) {
        final success = await AuthService.instance.updateUserLanguage(languageCode);
        if (!success) {
          // If cloud save fails, still keep local change
          print('Warning: Failed to save language to cloud, but local change preserved');
        }
        return success;
      }

      return true;
    } catch (e) {
      print('Error updating language: $e');
      return false;
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