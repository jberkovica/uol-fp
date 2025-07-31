import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/story.dart';
import 'language_service.dart';
import 'logging_service.dart';

/// Efficient AI service implementation using backend API with:
/// - Gemini 2.0 Flash for image captioning
/// - Mistral Medium for story generation
/// - ElevenLabs Callum voice for TTS
/// - No file storage required - uses base64 processing
class AIStoryService {
  static final AIStoryService _instance = AIStoryService._internal();
  factory AIStoryService() => _instance;
  AIStoryService._internal();
  
  static final _logger = LoggingService.getLogger('AIStoryService');

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
      _logger.i('Starting efficient story generation from image');

      // Read image as bytes
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Convert to base64
      String base64Image = base64Encode(imageBytes);

      // Determine MIME type
      String mimeType = _getMimeType(imageFile.name);

      _logger.d(
          'Image converted to base64 (${base64Image.length} chars), MIME: $mimeType');

      // Get user's language preference from single source of truth
      String userLanguage = LanguageService.instance.currentLanguageCode;
      _logger.i('Story generation using language: $userLanguage');

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

      _logger.i('Story generation response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String storyId = responseData['story_id'];
        _logger.i('Story generation initiated: $storyId');

        // Poll for story completion
        Story? story;
        int attempts = 0;
        const maxAttempts =
            30; // 30 attempts with 2-second delays = 1 minute max

        _logger.d('Polling for story completion...');
        while (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));

          story = await getStory(storyId);
          _logger.d('Attempt ${attempts + 1}: Story status is ${story.status}');

          if (story.status == StoryStatus.approved || story.status == StoryStatus.pending) {
            // Story generation completed! 
            // - approved: Ready for playback
            // - pending: Ready but needs parent approval
            _logger.i('Story generation completed! Status: ${story.status}');
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
        _logger.e('Story generation failed', error: 'HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
            'HTTP ${response.statusCode}: Failed to generate story');
      }
    } catch (e) {
      _logger.e('Error in generateStoryFromImageFile', error: e);
      throw Exception('Failed to generate story: $e');
    }
  }

  /// Initiate a new voice story in transcribing state
  Future<String> initiateVoiceStory(String kidId) async {
    try {
      _logger.i('Initiating voice story for kid: $kidId');
      
      // Get user's language preference
      String userLanguage = LanguageService.instance.currentLanguageCode;
      
      final response = await http.post(
        Uri.parse('$baseUrl/stories/initiate-voice'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'kid_id': kidId,
          'language': userLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final storyId = responseData['story_id'] as String;
        _logger.i('Story initiated successfully: $storyId');
        return storyId;
      } else {
        throw Exception('Failed to initiate voice story: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error initiating voice story', error: e);
      throw Exception('Failed to initiate voice story: $e');
    }
  }

  /// Transcribe audio for a story
  Future<String> transcribeAudio(String storyId, String audioPath) async {
    try {
      _logger.i('Transcribing audio for story: $storyId');
      
      // Handle different audio path formats (file path vs blob URL)
      Uint8List audioBytes;
      
      if (audioPath.startsWith('blob:')) {
        // Web blob URL - need to fetch the blob data
        final response = await http.get(Uri.parse(audioPath));
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch audio blob: ${response.statusCode}');
        }
        audioBytes = response.bodyBytes;
      } else {
        // File path - read the file
        final file = File(audioPath);
        if (!await file.exists()) {
          throw Exception('Audio file not found: $audioPath');
        }
        audioBytes = await file.readAsBytes();
      }

      // Convert to base64
      final base64Audio = base64Encode(audioBytes);

      final response = await http.post(
        Uri.parse('$baseUrl/stories/transcribe'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'story_id': storyId,
          'audio_data': base64Audio,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final transcribedText = responseData['transcribed_text'] as String;
        _logger.i('Audio transcribed successfully: ${transcribedText.length} characters');
        return transcribedText;
      } else {
        throw Exception('Failed to transcribe audio: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error transcribing audio', error: e);
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  /// Submit final text for story generation
  Future<Story> submitStoryText(String storyId, String text) async {
    try {
      _logger.i('Submitting story text for generation: $storyId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/stories/submit-text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'story_id': storyId,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _logger.i('Story text submitted successfully');
        
        // Poll for story completion
        Story? story;
        int attempts = 0;
        const maxAttempts = 30; // 30 attempts with 2-second delays = 1 minute max

        _logger.d('Polling for story completion...');
        while (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));

          story = await getStory(storyId);
          _logger.d('Attempt ${attempts + 1}: Story status is ${story.status}');

          if (story.status == StoryStatus.approved || story.status == StoryStatus.pending) {
            // Story generation completed! 
            // - approved: Ready for playback
            // - pending: Ready but needs parent approval
            _logger.i('Story generation completed! Status: ${story.status}');
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
        throw Exception('Failed to submit story text: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error submitting story text', error: e);
      throw Exception('Failed to submit story text: $e');
    }
  }

  /// Generate story from audio recording (DEPRECATED - use new flow)
  Future<Story> generateStoryFromAudio(String audioPath, String kidId) async {
    try {
      _logger.i('Starting story generation from audio recording');
      _logger.d('Audio file path: $audioPath');

      // Get user's language preference
      String userLanguage = LanguageService.instance.currentLanguageCode;
      _logger.i('Story generation using language: $userLanguage');

      // Handle different audio path formats (file path vs blob URL)
      Uint8List audioBytes;
      
      if (audioPath.startsWith('blob:')) {
        // Web blob URL - need to fetch the blob data
        final response = await http.get(Uri.parse(audioPath));
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch audio blob: ${response.statusCode}');
        }
        audioBytes = response.bodyBytes;
      } else {
        // File path - read the file
        final audioFile = File(audioPath);
        if (!await audioFile.exists()) {
          throw Exception('Audio file not found at path: $audioPath');
        }
        audioBytes = await audioFile.readAsBytes();
      }

      final audioBase64 = base64Encode(audioBytes);

      // Call the audio-based story generation endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/generate-story-from-audio/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'kid_id': kidId,
          'audio_data': audioBase64,
          'language': userLanguage,
          'preferences': null,
        }),
      );

      _logger.i('Story generation response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String storyId = responseData['story_id'];
        _logger.i('Story generation initiated: $storyId');

        // Poll for story completion (same logic as text/image)
        Story? story;
        int attempts = 0;
        const maxAttempts = 30; // 30 attempts with 2-second delays = 1 minute max

        _logger.d('Polling for story completion...');
        while (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));

          story = await getStory(storyId);
          _logger.d('Attempt ${attempts + 1}: Story status = ${story?.status}');

          if (story != null && (story.status == StoryStatus.approved || story.status == StoryStatus.pending)) {
            _logger.i('Story generation completed: ${story.id}');
            return story;
          }

          if (story != null && story.status == StoryStatus.rejected) {
            throw Exception('Story generation failed on server');
          }

          attempts++;
        }

        throw Exception('Story generation timed out after ${maxAttempts * 2} seconds');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to generate story: ${errorData['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _logger.e('Story generation from audio failed', error: e);
      rethrow;
    }
  }

  /// Generate story from text input
  Future<Story> generateStoryFromText(String textInput, String kidId) async {
    try {
      _logger.i('Starting story generation from text input');
      _logger.d('Text input: ${textInput.length} characters');

      // Get user's language preference
      String userLanguage = LanguageService.instance.currentLanguageCode;
      _logger.i('Story generation using language: $userLanguage');

      // Call the text-based story generation endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/generate-story-from-text/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'kid_id': kidId,
          'text_input': textInput,
          'language': userLanguage,
          'preferences': null,
        }),
      );

      _logger.i('Story generation response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String storyId = responseData['story_id'];
        _logger.i('Story generation initiated: $storyId');

        // Poll for story completion (same logic as image)
        Story? story;
        int attempts = 0;
        const maxAttempts = 30; // 30 attempts with 2-second delays = 1 minute max

        _logger.d('Polling for story completion...');
        while (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));

          story = await getStory(storyId);
          _logger.d('Attempt ${attempts + 1}: Story status is ${story.status}');

          if (story.status == StoryStatus.approved || story.status == StoryStatus.pending) {
            _logger.i('Story generation completed! Status: ${story.status}');
            break;
          } else if (story.status == StoryStatus.rejected) {
            throw Exception('Story generation failed on backend');
          }

          attempts++;
        }

        if (story == null || (story.status != StoryStatus.approved && story.status != StoryStatus.pending)) {
          throw Exception(
              'Story generation timed out or failed after $attempts attempts');
        }

        return story;
      } else {
        _logger.e('Story generation failed', error: 'HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
            'HTTP ${response.statusCode}: Failed to generate story');
      }
    } catch (e) {
      _logger.e('Error in generateStoryFromText', error: e);
      throw Exception('Failed to generate story: $e');
    }
  }

  /// Get story details from backend
  Future<Story> getStory(String storyId) async {
    try {
      final uri = Uri.parse('$baseUrl/stories/$storyId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return Story.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get story');
      }
    } catch (e) {
      _logger.e('Error getting story', error: e);
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
      _logger.e('Error getting pending stories', error: e);
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
      _logger.e('Error getting approved stories', error: e);
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
      _logger.e('Error reviewing story', error: e);
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
