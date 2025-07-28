import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/kid.dart';
import '../models/story.dart';
import 'logging_service.dart';

/// Service for managing kid profiles through the backend API
class KidService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static final _logger = LoggingService.getLogger('KidService');
  
  // Simple in-memory cache to reduce database calls
  static final Map<String, List<Kid>> _kidsCache = {};
  static final Map<String, List<Story>> _storiesCache = {};
  static DateTime? _lastCacheUpdate;

  /// Get all kids for a specific user
  static Future<List<Kid>> getKidsForUser(String userId) async {
    // Check cache first (cache for 5 minutes)
    if (_kidsCache.containsKey(userId) && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
      return _kidsCache[userId]!;
    }

    try {
      final uri = Uri.parse('$baseUrl/kids/user/$userId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> kidsData = responseData['kids'] ?? [];
        final kids = kidsData.map((item) => Kid.fromJson(item)).toList();
        
        // Update cache
        _kidsCache[userId] = kids;
        _lastCacheUpdate = DateTime.now();
        
        return kids;
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get kids for user');
      }
    } catch (e) {
      _logger.e('Error getting kids for user', error: e);
      throw Exception('Failed to get kids: $e');
    }
  }

  /// Create a new kid profile
  static Future<Kid> createKid({
    required String userId,
    required String name,
    int? age,
    String avatarType = 'profile1',
    String? hairColor,
    String? hairLength,
    String? skinColor,
    String? eyeColor,
    String? gender,
    List<String>? favoriteGenres,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/kids/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name.trim(),
          'age': age,
          'avatar_type': avatarType,
          'hair_color': hairColor,
          'hair_length': hairLength,
          'skin_color': skinColor,
          'eye_color': eyeColor,
          'gender': gender,
          'favorite_genres': favoriteGenres ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        clearCache(); // Clear cache when data changes
        return Kid.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to create kid');
      }
    } catch (e) {
      _logger.e('Error creating kid', error: e);
      throw Exception('Failed to create kid: $e');
    }
  }

  /// Get a specific kid by ID
  static Future<Kid> getKid(String kidId) async {
    try {
      final uri = Uri.parse('$baseUrl/kids/$kidId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Kid.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Kid not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get kid');
      }
    } catch (e) {
      _logger.e('Error getting kid', error: e);
      throw Exception('Failed to get kid: $e');
    }
  }

  /// Update a kid's information
  static Future<Kid> updateKid({
    required String kidId,
    String? name,
    int? age,
    String? avatarType,
    String? hairColor,
    String? hairLength,
    String? skinColor,
    String? eyeColor,
    String? gender,
    List<String>? favoriteGenres,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/kids/$kidId');
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name.trim();
      if (age != null) updateData['age'] = age;
      if (avatarType != null) updateData['avatar_type'] = avatarType;
      if (hairColor != null) updateData['hair_color'] = hairColor;
      if (hairLength != null) updateData['hair_length'] = hairLength;
      if (skinColor != null) updateData['skin_color'] = skinColor;
      if (eyeColor != null) updateData['eye_color'] = eyeColor;
      if (gender != null) updateData['gender'] = gender;
      if (favoriteGenres != null) updateData['favorite_genres'] = favoriteGenres;
      if (notes != null) updateData['notes'] = notes;

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        clearCache(); // Clear cache when data changes
        return Kid.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Kid not found');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update kid');
      }
    } catch (e) {
      _logger.e('Error updating kid', error: e);
      throw Exception('Failed to update kid: $e');
    }
  }

  /// Delete a kid and all associated stories
  static Future<void> deleteKid(String kidId) async {
    try {
      final uri = Uri.parse('$baseUrl/kids/$kidId');
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        clearCache(); // Clear cache when data changes
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Kid not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to delete kid');
      }
    } catch (e) {
      _logger.e('Error deleting kid', error: e);
      throw Exception('Failed to delete kid: $e');
    }
  }

  /// Get all stories for a specific kid
  static Future<List<Story>> getStoriesForKid(String kidId) async {
    // Check cache first (cache for 2 minutes for stories)
    if (_storiesCache.containsKey(kidId) && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 2) {
      return _storiesCache[kidId]!;
    }

    try {
      final uri = Uri.parse('$baseUrl/kids/$kidId/stories');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final stories = data.map((item) => Story.fromJson(item)).toList();
        
        // Update cache
        _storiesCache[kidId] = stories;
        _lastCacheUpdate = DateTime.now();
        
        return stories;
      } else if (response.statusCode == 404) {
        throw Exception('Kid not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get stories');
      }
    } catch (e) {
      _logger.e('Error getting stories for kid', error: e);
      throw Exception('Failed to get stories: $e');
    }
  }
  
  /// Clear cache (call when data changes)
  static void clearCache() {
    _kidsCache.clear();
    _storiesCache.clear();
    _lastCacheUpdate = null;
  }
}