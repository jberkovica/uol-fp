import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/story.dart';
import '../test_helpers.dart';

void main() {
  group('Story Model - Enhanced Tests', () {
    
    group('Story Builder Pattern', () {
      test('should create story with builder pattern', () {
        final story = StoryBuilder()
          .withId('builder-test-123')
          .withTitle('Builder Story')
          .withChildName('Builder Child')
          .withStatus(StoryStatus.pending)
          .build();

        expect(story.id, equals('builder-test-123'));
        expect(story.title, equals('Builder Story'));
        expect(story.childName, equals('Builder Child'));
        expect(story.status, equals(StoryStatus.pending));
      });

      test('should create story with special characters using builder', () {
        final story = StoryBuilder()
          .withSpecialCharacters()
          .build();

        expect(story.title, contains('quotes'));
        expect(story.title, contains('🏰'));
        expect(story.content, contains('Привет мир'));
        expect(story.childName, equals('José María'));
      });

      test('should create story with long content using builder', () {
        final story = StoryBuilder()
          .withLongContent()
          .build();

        expect(story.content.length, greaterThan(1000));
        expect(story.content, contains('Very long story content'));
      });

      test('should create story with future date using builder', () {
        final now = DateTime.now();
        final story = StoryBuilder()
          .withFutureDate()
          .build();

        expect(story.createdAt.isAfter(now), isTrue);
      });
    });

    group('Error Boundary Testing', () {
      test('should handle malformed JSON gracefully', () {
        final malformedInputs = [
          <String, dynamic>{}, // completely empty
          {'story_id': null}, // null required field
          {'story_id': 123}, // wrong type for string field
          {'story_id': 'valid', 'created_at': 'invalid-date'}, // invalid date
          {'story_id': 'valid', 'status': 'invalid-status'}, // invalid status
        ];

        for (final input in malformedInputs) {
          expect(() {
            final story = Story.fromJson(input);
            // If we get here, at least verify the story has safe defaults
            expect(story.id, isA<String>());
            expect(story.title, isA<String>());
            expect(story.content, isA<String>());
            expect(story.childName, isA<String>());
            expect(story.createdAt, isA<DateTime>());
          }, returnsNormally, reason: 'Should handle malformed input: $input');
        }
      });

      test('should handle extremely large JSON values', () {
        final extremeValues = {
          'story_id': TestDataFactory.generateText(1000),
          'title': TestDataFactory.generateText(10000),
          'content': TestDataFactory.generateText(100000),
          'child_name': TestDataFactory.generateText(500),
          'created_at': DateTime.now().toIso8601String(),
        };

        expect(() {
          final story = Story.fromJson(extremeValues);
          expect(story.id.length, equals(1000));
          expect(story.title.length, equals(10000));
          expect(story.content.length, equals(100000));
        }, returnsNormally);
      });

      test('should handle null and empty string edge cases', () {
        final edgeCases = [
          {'story_id': '', 'created_at': DateTime.now().toIso8601String()},
          {'story_id': '   ', 'created_at': DateTime.now().toIso8601String()},
          {'story_id': 'valid', 'title': '', 'created_at': DateTime.now().toIso8601String()},
          {'story_id': 'valid', 'content': '', 'created_at': DateTime.now().toIso8601String()},
          {'story_id': 'valid', 'child_name': '', 'created_at': DateTime.now().toIso8601String()},
        ];

        for (final testCase in edgeCases) {
          final story = Story.fromJson(testCase);
          expect(story.id, isA<String>());
          expect(story.title, isA<String>());
          expect(story.content, isA<String>());
          expect(story.childName, isA<String>());
        }
      });
    });

    group('Property-Based Testing', () {
      test('JSON serialization roundtrip property', () {
        // Test with multiple random variations
        for (int i = 0; i < 20; i++) {
          final originalStory = _generateRandomStory(i);
          
          // Roundtrip: Story -> JSON -> Story
          final json = originalStory.toJson();
          final reconstructedStory = Story.fromJson(json);

          expect(reconstructedStory.id, equals(originalStory.id));
          expect(reconstructedStory.title, equals(originalStory.title));
          expect(reconstructedStory.content, equals(originalStory.content));
          expect(reconstructedStory.status, equals(originalStory.status));
          expect(reconstructedStory.childName, equals(originalStory.childName));
          expect(reconstructedStory.imageUrl, equals(originalStory.imageUrl));
          expect(reconstructedStory.audioUrl, equals(originalStory.audioUrl));
          // Note: DateTime precision might differ slightly, so we check within reasonable bounds
          expect(reconstructedStory.createdAt.difference(originalStory.createdAt).abs(),
              lessThan(const Duration(seconds: 1)));
        }
      });

      test('story validation properties hold for various inputs', () {
        final testNames = TestDataFactory.generateTestNames();
        
        for (final name in testNames) {
          final story = StoryBuilder()
            .withChildName(name)
            .build();
          
          // Property: childName should always be stored as provided
          expect(story.childName, equals(name));
          
          // Property: story should always have valid creation time
          expect(story.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))) || 
                 story.createdAt.isAtSameMomentAs(DateTime.now().add(const Duration(seconds: 1))), isTrue);
        }
      });

      test('content length variations preserve data integrity', () {
        final contentVariations = TestDataFactory.generateStoryContents();
        
        for (final content in contentVariations) {
          final story = StoryBuilder()
            .withContent(content)
            .build();
          
          // Property: content should be preserved exactly
          expect(story.content, equals(content));
          
          // Property: JSON roundtrip should preserve content
          final json = story.toJson();
          final reconstructed = Story.fromJson(json);
          expect(reconstructed.content, equals(content));
        }
      });
    });

    group('Performance Characteristics', () {
      test('story creation performance', () {
        const iterations = 1000;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          StoryBuilder()
            .withId('perf-test-$i')
            .withTitle('Performance Test Story $i')
            .build();
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Creating $iterations stories should take less than 100ms');
      });

      test('JSON parsing performance', () {
        final largeStoryJson = {
          'story_id': 'performance-test',
          'title': TestDataFactory.generateText(1000, char: 'Title '),
          'content': TestDataFactory.generateText(10000, char: 'Content '),
          'child_name': 'Performance Test Child',
          'status': 'approved',
          'created_at': DateTime.now().toIso8601String(),
        };

        const iterations = 100;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          Story.fromJson(largeStoryJson);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Parsing $iterations large stories should take less than 50ms');
      });
    });

    group('Validation Logic Testing', () {
      test('should validate name using consistent pattern', () {
        final validNames = ['Alice', 'José María', 'André-Paul', "O'Connor", 'Žūūū', 'Анна'];
        final invalidNames = ['123', 'Test@User', 'User.Name', 'User_Name', ''];

        for (final name in validNames) {
          expect(TestConstants.namePattern.hasMatch(name), isTrue,
            reason: '$name should be valid according to name pattern');
        }

        for (final name in invalidNames) {
          expect(TestConstants.namePattern.hasMatch(name), isFalse,
            reason: '$name should be invalid according to name pattern');
        }
      });

      test('should validate content length boundaries', () {
        // Test exact boundary conditions
        final boundaryTests = [
          ('', 0), // minimum
          ('A', 1), // just above minimum
          (TestDataFactory.generateText(TestConstants.maxContentLength - 1), TestConstants.maxContentLength - 1), // just below max
          (TestDataFactory.generateText(TestConstants.maxContentLength), TestConstants.maxContentLength), // exact max
          (TestDataFactory.generateText(TestConstants.maxContentLength + 1), TestConstants.maxContentLength + 1), // just above max
        ];

        for (final (content, expectedLength) in boundaryTests) {
          final story = StoryBuilder().withContent(content).build();
          expect(story.content.length, equals(expectedLength));
          
          // All lengths should be accepted by the model (business rules apply elsewhere)
          expect(story.content, equals(content));
        }
      });

      test('should handle status enum edge cases', () {
        for (final statusString in TestConstants.validStatusStrings) {
          final response = TestDataFactory.createStoryGenerationResponse(status: statusString);
          final story = Story.fromJson(response);
          
          // Should parse to valid enum value
          expect(story.status, isA<StoryStatus>());
          
          // Should roundtrip correctly
          final json = story.toJson();
          expect(json['status'], isA<String>());
        }
      });
    });
  });
}

/// Generate a pseudo-random story for property testing
Story _generateRandomStory(int seed) {
  final random = seed; // Simple deterministic "randomness"
  
  final statuses = StoryStatus.values;
  final contents = TestDataFactory.generateStoryContents();
  final names = TestDataFactory.generateTestNames(includeInvalid: false);
  
  final builder = StoryBuilder()
    .withId('random-$seed')
    .withTitle('Random Story $seed')
    .withContent(contents[random % contents.length])
    .withStatus(statuses[random % statuses.length])
    .withChildName(names[random % names.length])
    .withCreatedAt(DateTime.now().subtract(Duration(days: random % 365)));
    
  if (random % 2 == 0) {
    builder.withImageUrl('https://example.com/image$seed.jpg');
  }
  
  if (random % 3 == 0) {
    builder.withAudioUrl('https://example.com/audio$seed.mp3');
  }
  
  return builder.build();
}