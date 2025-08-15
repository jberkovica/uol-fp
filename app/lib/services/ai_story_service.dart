import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/story.dart';
import 'language_service.dart';
import 'logging_service.dart';

/// Result of story generation with navigation context
class StoryGenerationResult {
  final Story story;
  final StoryCompletionType completionType;
  
  const StoryGenerationResult({
    required this.story,
    required this.completionType,
  });
}

/// How a story generation completed
enum StoryCompletionType {
  readyToRead,        // Story is approved and ready to read immediately
  waitingForApproval, // Story is pending parent approval
  failed,            // Story generation failed
}

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
        return StoryStatus.processing;
      default:
        return StoryStatus.processing; // Default to processing for unknown states
    }
  }


  /// Initialize the service
  void initialize() {
    _updateStreams();
  }

  /// Robust polling for story completion with exponential backoff
  Future<StoryGenerationResult> _pollForStoryCompletion(String storyId) async {
    Story? story;
    int attempts = 0;
    const maxAttempts = 20; // Reduced max attempts due to exponential backoff
    
    // Exponential backoff: start at 1s, max 8s
    int getDelaySeconds(int attempt) {
      final delaySeconds = (1 * (1 << attempt)).clamp(1, 8); // 1, 2, 4, 8, 8, 8...
      return delaySeconds;
    }

    _logger.d('Starting polling for story completion with exponential backoff...');
    while (attempts < maxAttempts) {
      final delaySeconds = getDelaySeconds(attempts);
      _logger.d('Attempt ${attempts + 1}: waiting ${delaySeconds}s before next poll');
      await Future.delayed(Duration(seconds: delaySeconds));

      story = await getStory(storyId);
      _logger.d('Attempt ${attempts + 1}: Story status is ${story.status}');

      // Story is ready to read immediately
      if (story.status == StoryStatus.approved) {
        _logger.i('Story generation completed and approved! Status: ${story.status}');
        return StoryGenerationResult(
          story: story,
          completionType: StoryCompletionType.readyToRead,
        );
      }
      
      // Story needs parent approval - stop polling, this is complete
      if (story.status == StoryStatus.pending) {
        _logger.i('Story generation completed, waiting for parent approval. Status: ${story.status}');
        return StoryGenerationResult(
          story: story,
          completionType: StoryCompletionType.waitingForApproval,
        );
      }
      
      // Story was rejected - this is a failure
      if (story.status == StoryStatus.rejected) {
        _logger.e('Story was rejected by backend or parent');
        return StoryGenerationResult(
          story: story,
          completionType: StoryCompletionType.failed,
        );
      }

      // Status is still processing - continue polling
      if (story.status == StoryStatus.processing) {
        _logger.d('Story still processing, continuing to poll...');
        attempts++;
        continue;
      }

      // Unknown status - treat as processing and continue
      _logger.w('Unknown story status: ${story.status}, treating as processing');
      attempts++;
    }

    // Timeout - return the last known story state
    if (story != null) {
      _logger.e('Story generation timed out after $attempts attempts. Last status: ${story.status}');
      return StoryGenerationResult(
        story: story,
        completionType: StoryCompletionType.failed,
      );
    } else {
      throw Exception('Story generation timed out and no story data received');
    }
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
  Future<StoryGenerationResult> generateStoryFromImageFile(
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
        Uri.parse('$baseUrl/stories/generate'),
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

        // Use robust polling logic
        return await _pollForStoryCompletion(storyId);
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
  Future<StoryGenerationResult> submitStoryText(String storyId, String text) async {
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
        jsonDecode(response.body); // Response received
        _logger.i('Story text submitted successfully');
        
        // Use robust polling logic
        return await _pollForStoryCompletion(storyId);
      } else {
        throw Exception('Failed to submit story text: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error submitting story text', error: e);
      throw Exception('Failed to submit story text: $e');
    }
  }

  /// Generate story from audio recording (DEPRECATED - use new flow)
  Future<StoryGenerationResult> generateStoryFromAudio(String audioPath, String kidId) async {
    try {
      _logger.i('Starting story generation from audio recording');
      _logger.d('Audio file path: $audioPath');

      // Get user's language preference
      String userLanguage = LanguageService.instance.currentLanguageCode;
      _logger.i('Story generation using language: $userLanguage');

      // Use the new voice workflow for audio-based story generation
      final storyId = await initiateVoiceStory(kidId);
      
      // Transcribe the audio first
      final transcribedText = await transcribeAudio(storyId, audioPath);
      
      // Submit the transcribed text for story generation
      final response = await http.post(
        Uri.parse('$baseUrl/stories/submit-text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'story_id': storyId,
          'text': transcribedText,
        }),
      );

      _logger.i('Story generation response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        jsonDecode(response.body); // Response received
        _logger.i('Audio story generation initiated: $storyId');

        // Use robust polling logic
        return await _pollForStoryCompletion(storyId);
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
  Future<StoryGenerationResult> generateStoryFromText(String textInput, String kidId) async {
    try {
      _logger.i('Starting story generation from text input');
      _logger.d('Text input: ${textInput.length} characters');

      // Get user's language preference
      String userLanguage = LanguageService.instance.currentLanguageCode;
      _logger.i('Story generation using language: $userLanguage');

      // For text input, use the text-specific initiate endpoint
      // Step 1: Initiate story (creates in DRAFT state for text)
      final initResponse = await http.post(
        Uri.parse('$baseUrl/stories/initiate-text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'kid_id': kidId,
          'language': userLanguage,
        }),
      );
      
      if (initResponse.statusCode != 200) {
        throw Exception('Failed to initiate text story: ${initResponse.statusCode}');
      }
      
      final initData = jsonDecode(initResponse.body);
      final storyId = initData['story_id'] as String;
      _logger.i('Text story initiated: $storyId');
      
      // Step 2: Now submit the actual text
      final response = await http.post(
        Uri.parse('$baseUrl/stories/submit-text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'story_id': storyId,
          'text': textInput,
        }),
      );

      _logger.i('Story generation response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        jsonDecode(response.body); // Response received
        _logger.i('Text story generation initiated: $storyId');

        // Use robust polling logic
        return await _pollForStoryCompletion(storyId);
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
                  audioUrl: item['audio_url'],
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
