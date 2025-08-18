import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/kid.dart';
import '../constants/api_constants.dart';
import '../services/logging_service.dart';

/// Clean repository pattern for kid profile management
/// Handles all kid-related data operations
class KidRepository {
  static final _logger = LoggingService.getLogger('KidRepository');
  
  // Dependencies - can be injected for testing
  final http.Client _httpClient;
  
  // Simple in-memory cache
  static final Map<String, CachedData<List<Kid>>> _cache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  /// Constructor with optional dependency injection for testing
  KidRepository({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();
  
  /// Fetch all kids for a user
  Future<List<Kid>> getKidsForUser(String userId) async {
    try {
      // Check cache first
      final cached = _cache[userId];
      if (cached != null && !cached.isExpired) {
        _logger.d('Returning cached kids for user: $userId');
        return cached.data;
      }
      
      // Fetch from backend
      final url = Uri.parse('${ApiConstants.baseUrl}/kids/user/$userId');
      _logger.d('Fetching kids from backend: $url');
      
      final response = await _httpClient.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final kids = (data['kids'] as List)
            .map((item) => Kid.fromJson(item))
            .toList();
        
        // Update cache
        _cache[userId] = CachedData(kids);
        
        _logger.i('Fetched ${kids.length} kids for user: $userId');
        return kids;
      } else {
        _logger.e('Failed to fetch kids: ${response.statusCode}');
        throw Exception('Failed to fetch kids: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching kids for user $userId: $e');
      
      // Return cached data if available, even if expired
      final cached = _cache[userId];
      if (cached != null) {
        _logger.w('Returning expired cache due to error');
        return cached.data;
      }
      
      throw e;
    }
  }
  
  /// Get a stream of kids for a user
  Stream<List<Kid>> getKidsStream(String userId) {
    late StreamController<List<Kid>> controller;
    Timer? refreshTimer;
    
    controller = StreamController<List<Kid>>(
      onListen: () async {
        // Emit initial data
        try {
          final kids = await getKidsForUser(userId);
          if (!controller.isClosed) {
            controller.add(kids);
          }
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
        
        // Setup periodic refresh
        refreshTimer = Timer.periodic(_cacheTTL, (_) async {
          try {
            final kids = await getKidsForUser(userId);
            if (!controller.isClosed) {
              controller.add(kids);
            }
          } catch (e) {
            _logger.e('Error refreshing kids: $e');
          }
        });
      },
      onCancel: () {
        refreshTimer?.cancel();
        controller.close();
      },
    );
    
    return controller.stream;
  }
  
  /// Create a new kid profile
  Future<Kid> createKid({
    required String userId,
    required String name,
    required int age,
    String? gender,
    String avatarType = 'profile1',
    List<String> favoriteGenres = const [],
    String? parentNotes,
    String preferredLanguage = 'en',
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/kids');
      _logger.d('Creating new kid profile: $name');
      
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'name': name,
          'age': age,
          'gender': gender,
          'avatar_type': avatarType,
          'favorite_genres': favoriteGenres,
          'parent_notes': parentNotes,
          'preferred_language': preferredLanguage,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final kid = Kid.fromJson(data['kid']);
        
        // Clear cache to force refresh
        _cache.remove(userId);
        
        _logger.i('Created kid profile: ${kid.id}');
        return kid;
      } else {
        throw Exception('Failed to create kid: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error creating kid: $e');
      throw e;
    }
  }
  
  /// Update a kid profile
  Future<Kid> updateKid({
    required String kidId,
    required String name,
    required int age,
    String? gender,
    String? avatarType,
    List<String>? favoriteGenres,
    String? parentNotes,
    String? preferredLanguage,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/kids/$kidId');
      _logger.d('Updating kid profile: $kidId');
      
      final body = <String, dynamic>{
        'name': name,
        'age': age,
      };
      
      if (gender != null) body['gender'] = gender;
      if (avatarType != null) body['avatar_type'] = avatarType;
      if (favoriteGenres != null) body['favorite_genres'] = favoriteGenres;
      if (parentNotes != null) body['parent_notes'] = parentNotes;
      if (preferredLanguage != null) body['preferred_language'] = preferredLanguage;
      
      final response = await _httpClient.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final kid = Kid.fromJson(data['kid']);
        
        // Update cache if exists
        _updateKidInCache(kid);
        
        _logger.i('Updated kid profile: ${kid.id}');
        return kid;
      } else {
        throw Exception('Failed to update kid: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error updating kid $kidId: $e');
      throw e;
    }
  }
  
  /// Delete a kid profile
  Future<void> deleteKid(String kidId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/kids/$kidId');
      _logger.d('Deleting kid profile: $kidId');
      
      final response = await _httpClient.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Clear all caches as we don't know the user ID here
        _cache.clear();
        _logger.i('Deleted kid profile: $kidId');
      } else {
        throw Exception('Failed to delete kid: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error deleting kid $kidId: $e');
      throw e;
    }
  }
  
  /// Update a kid in all cached lists
  void _updateKidInCache(Kid updatedKid) {
    for (final entry in _cache.entries) {
      final kids = entry.value.data;
      final index = kids.indexWhere((k) => k.id == updatedKid.id);
      if (index != -1) {
        kids[index] = updatedKid;
        _logger.d('Updated kid ${updatedKid.id} in cache for user ${entry.key}');
      }
    }
  }
  
  /// Clear all cached data
  static void clearCache() {
    _cache.clear();
    _logger.i('Kid cache cleared');
  }
  
  // ===== TEST HELPER METHODS =====
  
  /// Clear cache for specific user - for testing
  @visibleForTesting
  void clearUserCache(String userId) {
    _cache.remove(userId);
    _logger.d('Cache cleared for user: $userId');
  }
}

/// Simple cache wrapper with TTL
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  
  CachedData(this.data) : timestamp = DateTime.now();
  
  bool get isExpired => 
      DateTime.now().difference(timestamp) > KidRepository._cacheTTL;
}