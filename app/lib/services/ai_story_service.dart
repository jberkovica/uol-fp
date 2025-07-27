import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/story.dart';
import 'language_service.dart';

/// Efficient AI service implementation using backend API with:
/// - Gemini 2.0 Flash for image captioning
/// - Mistral Medium for story generation
/// - ElevenLabs Callum voice for TTS
/// - No file storage required - uses base64 processing
class AIStoryService {
  static final AIStoryService _instance = AIStoryService._internal();
  factory AIStoryService() => _instance;
  AIStoryService._internal();

  // Image picker for photo selection
  final ImagePicker _picker = ImagePicker();

  // Controllers for real-time updates
  final _pendingStoriesController = StreamController<List<Story>>.broadcast();
  final _approvedStoriesController = StreamController<List<Story>>.broadcast();

  // In-memory storage (replace with Firestore later)
  final List<Story> _stories = [];

  // Stream getters
  Stream<List<Story>> get pendingStoriesStream =>
      _pendingStoriesController.stream;
  Stream<List<Story>> get approvedStoriesStream =>
      _approvedStoriesController.stream;

  // Backend URL - no file storage needed!
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Map backend status string to StoryStatus enum
  StoryStatus _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return StoryStatus.approved;
      case 'rejected':
        return StoryStatus.rejected;
      case 'pending':
        return StoryStatus.pending;
      case 'processing':
        return StoryStatus.pending; // Map processing to pending for UI
      default:
        return StoryStatus.pending;
    }
  }

  /// Initialize the service
  void initialize() {
    _updateStreams();
  }

  /// Pick image from camera or gallery
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Generate story directly from image file using efficient base64 processing
  /// No file upload required - processes image in memory
  Future<Story> generateStoryFromImageFile(
      XFile imageFile, String kidId) async {
    try {
      print('Starting efficient story generation from image...');

      // Read image as bytes
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Convert to base64
      String base64Image = base64Encode(imageBytes);

      // Determine MIME type
      String mimeType = _getMimeType(imageFile.name);

      print(
          'Image converted to base64 (${base64Image.length} chars), MIME: $mimeType');

      // Get user's language preference from single source of truth
      String userLanguage = LanguageService.instance.currentLanguageCode;
      print('Story generation using language: $userLanguage');

      // Call the new efficient endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/generate-story-from-image/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'kid_id': kidId,
          'image_data': base64Image,
          'mime_type': mimeType,
          'language': userLanguage,
          'preferences': null,
        }),
      );

      print('Story generation response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String storyId = responseData['story_id'];
        print('Story generation initiated: $storyId');

        // Poll for story completion
        Story? story;
        int attempts = 0;
        const maxAttempts =
            30; // 30 attempts with 2-second delays = 1 minute max

        print('Polling for story completion...');
        while (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));

          story = await getStory(storyId);
          print('Attempt ${attempts + 1}: Story status is ${story.status}');

          if (story.status == StoryStatus.approved || story.status == StoryStatus.pending) {
            // Story generation completed! 
            // - approved: Ready for playback
            // - pending: Ready but needs parent approval
            print('Story generation completed! Status: ${story.status}');
            break;
          } else if (story.status == StoryStatus.rejected) {
            throw Exception('Story generation failed on backend');
          }

          attempts++;
        }

        if (story == null || (story.status != StoryStatus.approved && story.status != StoryStatus.pending)) {
          throw Exception(
              'Story generation timed out or failed after ${attempts} attempts');
        }

        return story;
      } else {
        print('Error response: ${response.body}');
        throw Exception(
            'HTTP ${response.statusCode}: Failed to generate story');
      }
    } catch (e) {
      print('Error in generateStoryFromImageFile: $e');
      throw Exception('Failed to generate story: $e');
    }
  }

  /// Get story details from backend
  Future<Story> getStory(String storyId) async {
    try {
      final uri = Uri.parse('$baseUrl/story/$storyId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return Story.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get story');
      }
    } catch (e) {
      print('Error getting story: $e');
      throw Exception('Failed to get story: $e');
    }
  }

  /// Get all pending stories (for parent review)
  Future<List<Story>> getPendingStories() async {
    try {
      final uri = Uri.parse('$baseUrl/stories/pending');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['stories'] ?? [];
        return data
            .map((item) => Story(
                  id: item['id'] ?? item['story_id'],
                  title: item['title'] ?? 'Untitled Story',
                  content: item['content'] ?? '',
                  caption: item['image_description'] ?? item['caption'] ?? '',
                  imageUrl: '',
                  audioUrl: item['audio_url'],
                  status: _mapStatus(item['status']),
                  createdAt:
                      DateTime.tryParse(item['created_at']) ?? DateTime.now(),
                  childName: item['child_name'] ?? '',
                ))
            .toList();
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: Failed to get pending stories');
      }
    } catch (e) {
      print('Error getting pending stories: $e');
      throw Exception('Failed to get pending stories: $e');
    }
  }

  /// Get all approved stories (for child app)
  Future<List<Story>> getApprovedStories() async {
    try {
      final uri = Uri.parse('$baseUrl/stories/approved');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => Story(
                  id: item['story_id'],
                  title: item['title'] ?? 'Untitled Story',
                  content: item['content'] ?? '',
                  caption: item['caption'],
                  imageUrl: '',
                  audioUrl: item['audio_url'] != null
                      ? '$baseUrl${item['audio_url']}'
                      : null,
                  status: _mapStatus(item['status']),
                  createdAt:
                      DateTime.tryParse(item['created_at']) ?? DateTime.now(),
                  childName: item['child_name'],
                ))
            .toList();
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: Failed to get approved stories');
      }
    } catch (e) {
      print('Error getting approved stories: $e');
      throw Exception('Failed to get approved stories: $e');
    }
  }

  /// Review story (approve/reject)
  Future<void> reviewStory(String storyId, bool approved,
      {String? feedback}) async {
    try {
      final uri = Uri.parse('$baseUrl/stories/review-story/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'story_id': storyId,
          'approved': approved,
          'feedback': feedback,
        }),
      );

      if (response.statusCode == 200) {
        // Update local stories and streams
        final storyIndex = _stories.indexWhere((s) => s.id == storyId);
        if (storyIndex != -1) {
          _stories[storyIndex] = _stories[storyIndex].copyWith(
            status: approved ? StoryStatus.approved : StoryStatus.rejected,
          );
          _updateStreams();
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to review story');
      }
    } catch (e) {
      print('Error reviewing story: $e');
      throw Exception('Failed to review story: $e');
    }
  }

  /// Get audio URL for a story
  String getAudioUrl(String storyId) {
    return '$baseUrl/audio/$storyId';
  }

  /// Helper method to determine MIME type from file extension
  String _getMimeType(String fileName) {
    String extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Update streams with current data
  void _updateStreams() {
    final pending =
        _stories.where((s) => s.status == StoryStatus.pending).toList();
    final approved =
        _stories.where((s) => s.status == StoryStatus.approved).toList();

    _pendingStoriesController.add(pending);
    _approvedStoriesController.add(approved);
  }

  /// Dispose resources
  void dispose() {
    _pendingStoriesController.close();
    _approvedStoriesController.close();
  }

  // Legacy methods (deprecated - kept for compatibility)

  @deprecated
  Future<String> uploadImage(String imagePath) async {
    throw Exception(
        'Legacy method no longer supported. Use generateStoryFromImageFile directly.');
  }

  @deprecated
  Future<String> uploadImageFile(XFile imageFile) async {
    throw Exception(
        'Legacy method no longer supported. Use generateStoryFromImageFile directly.');
  }

  @deprecated
  Future<Story> generateStory(String imageId, String childName) async {
    throw Exception(
        'Legacy method no longer supported. Use generateStoryFromImageFile directly.');
  }
}
