import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/story.dart';
import '../services/logging_service.dart';

class StoryService {
  static final _logger = LoggingService.getLogger('StoryService');
  static const String baseUrl = ApiConstants.baseUrl;

  /// Toggle favourite status for a story
  static Future<Story> toggleStoryFavourite(String storyId, bool isFavourite) async {
    try {
      _logger.d('Toggling story $storyId favourite status to: $isFavourite');
      
      final requestBody = json.encode({
        'is_favourite': isFavourite,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/stories/$storyId/favourite'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      _logger.d('Toggle story favourite response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logger.d('Successfully toggled story favourite status');
        
        return Story.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to toggle story favourite: ${errorData['detail'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('Error toggling story favourite', error: e);
      throw Exception('Failed to toggle story favourite: $e');
    }
  }
}