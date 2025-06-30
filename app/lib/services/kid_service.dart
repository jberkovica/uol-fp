import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/kid.dart';
import '../models/story.dart';

/// Service for managing kid profiles through the backend API
class KidService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Get all kids for a specific user
  static Future<List<Kid>> getKidsForUser(String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/users/$userId/kids');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Kid.fromJson(item)).toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get kids for user');
      }
    } catch (e) {
      print('Error getting kids for user: $e');
      throw Exception('Failed to get kids: $e');
    }
  }

  /// Create a new kid profile
  static Future<Kid> createKid({
    required String userId,
    required String name,
    String avatarType = 'profile1',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/kids/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name.trim(),
          'avatar_type': avatarType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Kid.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to create kid');
      }
    } catch (e) {
      print('Error creating kid: $e');
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
      print('Error getting kid: $e');
      throw Exception('Failed to get kid: $e');
    }
  }

  /// Update a kid's information
  static Future<Kid> updateKid({
    required String kidId,
    String? name,
    String? avatarType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/kids/$kidId');
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name.trim();
      if (avatarType != null) updateData['avatar_type'] = avatarType;

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Kid.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Kid not found');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update kid');
      }
    } catch (e) {
      print('Error updating kid: $e');
      throw Exception('Failed to update kid: $e');
    }
  }

  /// Delete a kid and all associated stories
  static Future<void> deleteKid(String kidId) async {
    try {
      final uri = Uri.parse('$baseUrl/kids/$kidId');
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Kid not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to delete kid');
      }
    } catch (e) {
      print('Error deleting kid: $e');
      throw Exception('Failed to delete kid: $e');
    }
  }

  /// Get all stories for a specific kid
  static Future<List<Story>> getStoriesForKid(String kidId) async {
    try {
      final uri = Uri.parse('$baseUrl/kids/$kidId/stories');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Story.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        throw Exception('Kid not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get stories');
      }
    } catch (e) {
      print('Error getting stories for kid: $e');
      throw Exception('Failed to get stories: $e');
    }
  }
}