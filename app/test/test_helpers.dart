/// Test helpers and utilities for mocking services and data
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../lib/models/story.dart';
import '../lib/models/kid.dart';

/// Test data factory for creating test instances
class TestDataFactory {
  
  /// Create a test story with all required fields
  static Story createTestStory({
    String? id,
    String? title,
    String? content,
    StoryStatus? status,
    String? childName,
    String? imageUrl,
    String? audioUrl,
    String? caption,
    DateTime? createdAt,
    bool? isFavourite,
  }) {
    return Story(
      id: id ?? 'test-story-123',
      title: title ?? 'The Magic Forest',
      content: content ?? 'Once upon a time, there was a brave little mouse...',
      status: status ?? StoryStatus.approved,
      childName: childName ?? 'Alice',
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      caption: caption,
      createdAt: createdAt ?? DateTime.now(),
      isFavourite: isFavourite ?? false,
    );
  }
  
  /// Create a test kid with all required fields
  static Kid createTestKid({
    String? id,
    String? userId,
    String? name,
    int? age,
    String? avatarType,
    String? hairColor,
    String? hairLength,
    String? skinColor,
    String? eyeColor,
    String? gender,
    List<String>? favoriteGenres,
    DateTime? createdAt,
  }) {
    return Kid(
      id: id ?? 'test-kid-123',
      userId: userId ?? 'test-user-123',
      name: name ?? 'Alice',
      age: age ?? 7,
      avatarType: avatarType ?? 'profile1',
      hairColor: hairColor,
      hairLength: hairLength,
      skinColor: skinColor,
      eyeColor: eyeColor,
      gender: gender,
      favoriteGenres: favoriteGenres ?? [],
      createdAt: createdAt ?? DateTime.now(),
    );
  }
  
  /// Create test HTTP response
  static http.Response createHttpResponse({
    int? statusCode,
    String? body,
    Map<String, String>? headers,
  }) {
    return http.Response(
      body ?? '{"message": "success"}',
      statusCode ?? 200,
      headers: headers ?? {'content-type': 'application/json'},
    );
  }
  
  /// Create test story generation response
  static Map<String, dynamic> createStoryGenerationResponse({
    String? storyId,
    String? status,
    String? title,
    String? content,
  }) {
    return {
      'story_id': storyId ?? 'test-story-123',
      'status': status ?? 'approved',
      'title': title ?? 'The Magic Forest',
      'content': content ?? 'Once upon a time, there was a brave little mouse who lived in a cozy burrow under the old oak tree. Every day, the mouse would venture out to explore the wonderful world around him, meeting new friends and discovering amazing adventures that filled his heart with joy and wonder.',
      'audio_url': 'https://example.com/audio/test-story-123.mp3',
      'created_at': DateTime.now().toIso8601String(),
    };
  }
  
  /// Create test base64 image data (1x1 transparent PNG)
  static String createTestBase64Image() {
    return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  }
  
  /// Generate text of specified length for testing
  static String generateText(int length, {String char = 'A'}) {
    return char * length;
  }
  
  /// Generate test names with various characteristics
  static List<String> generateTestNames({
    bool includeValid = true,
    bool includeInvalid = true,
    bool includeInternational = true,
  }) {
    final names = <String>[];
    
    if (includeValid) {
      names.addAll(['Alice', 'Bob', 'Charlie', 'Diana', 'Eva']);
      if (includeInternational) {
        names.addAll(['María', 'José', 'André', 'Žūūū', 'Анна']);
      }
    }
    
    if (includeInvalid) {
      names.addAll([
        '', // empty
        '   ', // whitespace only
        '123', // numbers only
        'A', // too short
        generateText(30), // too long
        'Test@Name', // special characters
      ]);
    }
    
    return names;
  }
  
  /// Generate various story contents for testing edge cases
  static List<String> generateStoryContents() {
    return [
      // Normal content
      'Once upon a time, there was a brave little mouse who lived in a cozy burrow.',
      
      // Empty/minimal
      '',
      '   ',
      'Short',
      
      // Long content
      generateText(1000, char: 'A'),
      generateText(5000, char: 'Long story content with repeated text. '),
      
      // Special characters and unicode
      '''
        Once upon a time... 
        "Hello," said the mouse! 
        ¿Cómo estás? 
        Привет мир! 
        🐭🏰✨
        
        Line breaks and formatting included.
      ''',
      
      // Edge case formatting
      'Story\nwith\nnewlines',
      'Story\twith\ttabs',
      'Story with "quotes" and \'apostrophes\'',
    ];
  }
}

/// Builder pattern for creating test stories with fluent API
class StoryBuilder {
  String _id = 'test-story-123';
  String _title = 'Default Test Story';
  String _content = 'Once upon a time, there was a brave little mouse...';
  StoryStatus _status = StoryStatus.approved;
  String _childName = 'Alice';
  String? _imageUrl;
  String? _audioUrl;
  String? _caption;
  DateTime _createdAt = DateTime.now();

  StoryBuilder withId(String id) {
    _id = id;
    return this;
  }

  StoryBuilder withTitle(String title) {
    _title = title;
    return this;
  }

  StoryBuilder withContent(String content) {
    _content = content;
    return this;
  }

  StoryBuilder withStatus(StoryStatus status) {
    _status = status;
    return this;
  }

  StoryBuilder withChildName(String childName) {
    _childName = childName;
    return this;
  }

  StoryBuilder withImageUrl(String imageUrl) {
    _imageUrl = imageUrl;
    return this;
  }

  StoryBuilder withAudioUrl(String audioUrl) {
    _audioUrl = audioUrl;
    return this;
  }

  StoryBuilder withCaption(String caption) {
    _caption = caption;
    return this;
  }

  StoryBuilder withCreatedAt(DateTime createdAt) {
    _createdAt = createdAt;
    return this;
  }

  StoryBuilder withLongTitle() {
    _title = TestDataFactory.generateText(200, char: 'Very Long Title ');
    return this;
  }

  StoryBuilder withLongContent() {
    _content = TestDataFactory.generateText(5000, char: 'Very long story content with repeated text. ');
    return this;
  }

  StoryBuilder withSpecialCharacters() {
    _title = 'Story with "quotes" & émojis 🏰';
    _content = '''
      Once upon a time... 
      "Hello," said the mouse! 
      ¿Cómo estás? 
      Привет мир! 
      🐭🏰✨
    ''';
    _childName = 'José María';
    return this;
  }

  StoryBuilder withFutureDate() {
    _createdAt = DateTime.now().add(const Duration(days: 30));
    return this;
  }

  StoryBuilder withPastDate() {
    _createdAt = DateTime.now().subtract(const Duration(days: 365));
    return this;
  }

  Story build() {
    return Story(
      id: _id,
      title: _title,
      content: _content,
      status: _status,
      childName: _childName,
      imageUrl: _imageUrl,
      audioUrl: _audioUrl,
      caption: _caption,
      createdAt: _createdAt,
    );
  }
}

/// Constants for testing limits and boundaries
class TestConstants {
  static const int maxNameLength = 20;
  static const int minNameLength = 2;
  static const int maxContentLength = 5000;
  static const int maxPromptLength = 500;
  
  // Common validation patterns
  static final RegExp namePattern = RegExp(r"^[a-zA-Z\u00C0-\u017F\u0400-\u04FF\s\-']+$");
  static final RegExp base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
  
  static const List<String> supportedLanguages = ['en', 'ru', 'lv'];
  static const List<String> validStatusStrings = ['pending', 'approved', 'rejected', 'processing', 'completed'];
  
  /// Create test error response
  static Map<String, dynamic> createErrorResponse({
    String? message,
    int? statusCode,
  }) {
    return {
      'error': message ?? 'Test error message',
      'status_code': statusCode ?? 400,
    };
  }
}

/// Test utilities for common test operations
class TestUtils {
  
  /// Wait for async operations to complete
  static Future<void> waitForAsync() async {
    await Future.delayed(Duration.zero);
  }
  
  /// Pump and settle for widget tests
  static Future<void> pumpAndSettle(WidgetTester tester, [Duration? duration]) async {
    await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 100));
  }
}

/// HTTP response helper for creating test responses
class HttpResponseHelper {
  static http.Response createSuccessResponse(Map<String, dynamic> responseBody) {
    return http.Response(
      json.encode(responseBody),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  
  static http.Response createErrorResponse(int statusCode, String errorMessage) {
    return http.Response(
      json.encode({'error': errorMessage}),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

/// Main TestHelpers class with convenient static methods
class TestHelpers {
  /// Create a test story - convenience method
  static Story createTestStory({
    String? id,
    String? title,
    String? content,
    StoryStatus? status,
    String? childName,
    String? imageUrl,
    String? audioUrl,
    String? caption,
    DateTime? createdAt,
    bool? isFavourite,
  }) {
    return TestDataFactory.createTestStory(
      id: id,
      title: title,
      content: content,
      status: status,
      childName: childName,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      caption: caption,
      createdAt: createdAt,
      isFavourite: isFavourite,
    );
  }
  
  /// Create a test kid - convenience method
  static Kid createTestKid({
    String? id,
    String? userId,
    String? name,
    int? age,
    String? avatarType,
    String? hairColor,
    String? hairLength,
    String? skinColor,
    String? eyeColor,
    String? gender,
    List<String>? favoriteGenres,
    DateTime? createdAt,
  }) {
    return TestDataFactory.createTestKid(
      id: id,
      userId: userId,
      name: name,
      age: age,
      avatarType: avatarType,
      hairColor: hairColor,
      hairLength: hairLength,
      skinColor: skinColor,
      eyeColor: eyeColor,
      gender: gender,
      favoriteGenres: favoriteGenres,
      createdAt: createdAt,
    );
  }
}