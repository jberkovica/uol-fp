import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/background_music.dart';
import '../models/story.dart';
import '../services/logging_service.dart';

class BackgroundMusicService {
  static final _logger = LoggingService.getLogger('BackgroundMusicService');
  static const String baseUrl = ApiConstants.baseUrl;

  /// Get all available background music tracks
  static Future<BackgroundMusicResponse> getBackgroundMusicTracks() async {
    try {
      _logger.d('Fetching available background music tracks');
      
      final response = await http.get(
        Uri.parse('$baseUrl/stories/background-music'),
        headers: {'Content-Type': 'application/json'},
      );

      _logger.d('Background music tracks response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logger.d('Retrieved ${responseData['total']} background music tracks');
        return BackgroundMusicResponse.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to get background music tracks: ${errorData['detail'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('Error fetching background music tracks', error: e);
      throw Exception('Failed to fetch background music tracks: $e');
    }
  }

  /// Update story background music
  static Future<Story> updateStoryBackgroundMusic(String storyId, String backgroundMusicFilename) async {
    try {
      _logger.d('Updating story $storyId background music to: $backgroundMusicFilename');
      
      final requestBody = json.encode({
        'background_music_filename': backgroundMusicFilename,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/stories/$storyId/background-music'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      _logger.d('Update story background music response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logger.d('Successfully updated story background music');
        return Story.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to update story background music: ${errorData['detail'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('Error updating story background music', error: e);
      throw Exception('Failed to update story background music: $e');
    }
  }

  /// Extract current background music filename from URL
  static String? extractFilenameFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final segments = path.split('/');
      
      // URL format: /storage/v1/object/public/background-music/filename.mp3
      if (segments.length >= 6 && segments[segments.length - 2] == 'background-music') {
        String filename = segments.last.replaceAll('?', ''); // Remove query parameters
        // Decode URL encoding (e.g., %20 -> space)
        filename = Uri.decodeComponent(filename);
        return filename;
      }
      
      return null;
    } catch (e) {
      _logger.e('Error extracting filename from URL: $url', error: e);
      return null;
    }
  }
}