import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/kid.dart';

class AppStateService {
  static const String _selectedKidKey = 'selected_kid';
  static const String _authUserIdKey = 'auth_user_id';
  static const String _languageKey = 'app_language';
  
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('AppStateService not initialized. Call init() first.');
    }
    return _prefs!;
  }
  
  // Selected Kid persistence
  static Future<void> saveSelectedKid(Kid kid) async {
    final kidJson = jsonEncode(kid.toJson());
    await prefs.setString(_selectedKidKey, kidJson);
  }
  
  static Kid? getSelectedKid() {
    final kidJson = prefs.getString(_selectedKidKey);
    if (kidJson == null) return null;
    
    try {
      final kidMap = jsonDecode(kidJson) as Map<String, dynamic>;
      return Kid.fromJson(kidMap);
    } catch (e) {
      // If parsing fails, clear the invalid data
      clearSelectedKid();
      return null;
    }
  }
  
  static Future<void> clearSelectedKid() async {
    await prefs.remove(_selectedKidKey);
  }
  
  // Auth User ID persistence (for session management)
  static Future<void> saveAuthUserId(String userId) async {
    await prefs.setString(_authUserIdKey, userId);
  }
  
  static String? getAuthUserId() {
    return prefs.getString(_authUserIdKey);
  }
  
  static Future<void> clearAuthUserId() async {
    await prefs.remove(_authUserIdKey);
  }
  
  // Language preference persistence
  static Future<void> saveLanguage(String languageCode) async {
    await prefs.setString(_languageKey, languageCode);
  }
  
  static String? getLanguage() {
    return prefs.getString(_languageKey);
  }
  
  static Future<void> clearLanguage() async {
    await prefs.remove(_languageKey);
  }
  
  // Clear all app state (for logout)
  static Future<void> clearAllState() async {
    await Future.wait([
      clearSelectedKid(),
      clearAuthUserId(),
      // Note: Keep language preference on logout
    ]);
  }
}