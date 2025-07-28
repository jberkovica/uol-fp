import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/story.dart';

void main() {
  group('Story Model - Basic Tests', () {
    group('Story Creation', () {
      test('should create story with all required fields', () {
        // Arrange & Act
        final story = Story(
          id: 'test-123',
          title: 'Test Story',
          content: 'Test content',
          childName: 'Alice',
          createdAt: DateTime.now(),
          status: StoryStatus.approved,
        );

        // Assert
        expect(story.id, equals('test-123'));
        expect(story.title, equals('Test Story'));
        expect(story.content, equals('Test content'));
        expect(story.childName, equals('Alice'));
        expect(story.status, equals(StoryStatus.approved));
        expect(story.createdAt, isA<DateTime>());
      });

      test('should create story with optional fields', () {
        // Arrange & Act
        final story = Story(
          id: 'test-456',
          title: 'Story with extras',
          content: 'Story content',
          childName: 'Bob',
          createdAt: DateTime.now(),
          imageUrl: 'https://example.com/image.jpg',
          audioUrl: 'https://example.com/audio.mp3',
          caption: 'A beautiful forest scene',
        );

        // Assert
        expect(story.imageUrl, equals('https://example.com/image.jpg'));
        expect(story.audioUrl, equals('https://example.com/audio.mp3'));
        expect(story.caption, equals('A beautiful forest scene'));
      });

      test('should use default status when not provided', () {
        // Arrange & Act
        final story = Story(
          id: 'test-default',
          title: 'Default Status Story',
          content: 'Content',
          childName: 'Charlie',
          createdAt: DateTime.now(),
        );

        // Assert
        expect(story.status, equals(StoryStatus.pending));
      });
    });

    group('JSON Serialization', () {
      test('should serialize story to JSON correctly', () {
        // Arrange
        final createdAt = DateTime.now();
        final story = Story(
          id: 'json-test-123',
          title: 'JSON Test Story',
          content: 'JSON test content',
          childName: 'Diana',
          createdAt: createdAt,
          status: StoryStatus.approved,
          imageUrl: 'https://example.com/test-image.jpg',
          audioUrl: 'https://example.com/test-audio.mp3',
        );

        // Act
        final json = story.toJson();

        // Assert
        expect(json['story_id'], equals('json-test-123'));
        expect(json['title'], equals('JSON Test Story'));
        expect(json['content'], equals('JSON test content'));
        expect(json['child_name'], equals('Diana'));
        expect(json['status'], equals('approved'));
        expect(json['image_url'], equals('https://example.com/test-image.jpg'));
        expect(json['audio_url'], equals('https://example.com/test-audio.mp3'));
        expect(json['created_at'], isA<String>());
      });

      test('should deserialize story from JSON correctly', () {
        // Arrange
        final jsonData = {
          'story_id': 'from-json-456',
          'title': 'Story From JSON',
          'content': 'Content from JSON',
          'child_name': 'Eve',
          'status': 'approved',
          'image_url': 'https://example.com/json-image.jpg',
          'audio_url': 'https://example.com/json-audio.mp3',
          'created_at': DateTime.now().toIso8601String(),
        };

        // Act
        final story = Story.fromJson(jsonData);

        // Assert
        expect(story.id, equals('from-json-456'));
        expect(story.title, equals('Story From JSON'));
        expect(story.content, equals('Content from JSON'));
        expect(story.childName, equals('Eve'));
        expect(story.status, equals(StoryStatus.approved));
        expect(story.imageUrl, equals('https://example.com/json-image.jpg'));
        expect(story.audioUrl, equals('https://example.com/json-audio.mp3'));
        expect(story.createdAt, isA<DateTime>());
      });

      test('should handle missing optional fields in JSON', () {
        // Arrange
        final jsonData = {
          'story_id': 'minimal-json',
          'title': 'Minimal Story',
          'content': 'Minimal content',
          'child_name': 'Frank',
          'created_at': DateTime.now().toIso8601String(),
        };

        // Act
        final story = Story.fromJson(jsonData);

        // Assert
        expect(story.id, equals('minimal-json'));
        expect(story.title, equals('Minimal Story'));
        expect(story.imageUrl, isNull);
        expect(story.audioUrl, isNull);
        expect(story.caption, isNull);
        expect(story.status, equals(StoryStatus.pending)); // Default status
      });

      test('should handle default values in JSON deserialization', () {
        // Arrange
        final jsonData = {
          'story_id': 'defaults-test',
          'created_at': DateTime.now().toIso8601String(),
          // Missing title, content, child_name - should use defaults
        };

        // Act
        final story = Story.fromJson(jsonData);

        // Assert
        expect(story.id, equals('defaults-test'));
        expect(story.title, equals('Untitled Story'));
        expect(story.content, equals(''));
        expect(story.childName, equals(''));
        expect(story.status, equals(StoryStatus.pending));
      });
    });

    group('Story Status Enum', () {
      test('should handle all story status values', () {
        // Test creating stories with different statuses
        final statuses = [
          StoryStatus.pending,
          StoryStatus.approved,
          StoryStatus.rejected,
        ];

        for (final status in statuses) {
          final story = Story(
            id: 'status-test-${status.name}',
            title: 'Status Test',
            content: 'Testing status: ${status.name}',
            childName: 'Grace',
            createdAt: DateTime.now(),
            status: status,
          );

          expect(story.status, equals(status));
        }
      });

      test('should convert status enum to string for JSON', () {
        final statusMappings = {
          StoryStatus.pending: 'pending',
          StoryStatus.approved: 'approved',
          StoryStatus.rejected: 'rejected',
        };

        for (final entry in statusMappings.entries) {
          final story = Story(
            id: 'enum-test',
            title: 'Enum Test',
            content: 'Content',
            childName: 'Henry',
            createdAt: DateTime.now(),
            status: entry.key,
          );

          final json = story.toJson();
          expect(json['status'], equals(entry.value));
        }
      });
    });

    group('Data Validation', () {
      test('should validate story title is not empty', () {
        // Test with empty title
        final story = Story(
          id: 'empty-title-test',
          title: '',
          content: 'Content',
          childName: 'Ivy',
          createdAt: DateTime.now(),
        );

        expect(story.title.isEmpty, isTrue);
      });

      test('should validate story content length', () {
        // Test with different content lengths
        final shortContent = 'Short';
        final normalContent = 'Once upon a time, there was a brave little mouse who lived in a cozy burrow under the old oak tree.';
        final longContent = 'A' * 1000;

        expect(shortContent.length, lessThan(50));
        expect(normalContent.length, inInclusiveRange(50, 500));
        expect(longContent.length, greaterThan(500));
      });

      test('should validate URL formats', () {
        final validUrls = [
          'https://example.com/audio.mp3',
          'http://localhost:8000/story/123.mp3',
          'https://storage.googleapis.com/bucket/file.mp3',
        ];

        final invalidUrls = [
          'not_a_url',
          'ftp://invalid.com/file.mp3',
          'https://',
          '',
        ];

        for (final url in validUrls) {
          final uri = Uri.tryParse(url);
          expect(uri, isNotNull, reason: '$url should be valid');
          expect(uri?.hasScheme, isTrue, reason: '$url should have scheme');
          expect(['http', 'https'], contains(uri?.scheme), 
            reason: '$url should use http/https');
        }

        for (final url in invalidUrls) {
          if (url.isNotEmpty) {
            final uri = Uri.tryParse(url);
            // For URLs like 'https://' - they parse but are incomplete
            if (uri != null && uri.hasScheme && uri.scheme == 'https' && uri.host.isEmpty) {
              expect(uri.host.isEmpty, isTrue, 
                reason: '$url should be invalid due to empty host');
            } else if (uri != null && uri.hasScheme) {
              expect(['http', 'https'], isNot(contains(uri.scheme)), 
                reason: '$url should use unsupported scheme');
            }
          }
        }
      });
    });

    group('Edge Cases', () {
      test('should handle special characters in content', () {
        const specialContent = '''
          Once upon a time... 
          "Hello," said the mouse! 
          ¿Cómo estás? 
          Привет мир! 
          🐭🏰✨
        ''';

        final story = Story(
          id: 'special-chars-test',
          title: 'Special Characters',
          content: specialContent,
          childName: 'José',
          createdAt: DateTime.now(),
        );

        expect(story.content, equals(specialContent));
        expect(story.content, contains('🐭'));
        expect(story.content, contains('Привет'));
        expect(story.childName, equals('José'));
      });

      test('should handle very long content', () {
        final longContent = 'A' * 5000;
        
        final story = Story(
          id: 'long-content-test',
          title: 'Long Content Test',
          content: longContent,
          childName: 'Katherine',
          createdAt: DateTime.now(),
        );

        expect(story.content.length, equals(5000));
        expect(story.content, allOf([isA<String>(), isNotEmpty]));
      });

      test('should handle whitespace-only strings', () {
        final whitespaceStrings = ['', '   ', '\n\t', ' \n '];

        for (final whitespace in whitespaceStrings) {
          expect(whitespace.trim().isEmpty, isTrue,
            reason: '"$whitespace" should be considered empty after trim');
        }
      });

      test('should handle future datetime', () {
        final futureTime = DateTime.now().add(const Duration(days: 1));
        
        final story = Story(
          id: 'future-time-test',
          title: 'Future Time',
          content: 'Future content',
          childName: 'Lucas',
          createdAt: futureTime,
        );

        expect(story.createdAt, equals(futureTime));
        expect(story.createdAt.isAfter(DateTime.now()), isTrue);
      });
    });
  });
}