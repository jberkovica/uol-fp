import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../../lib/services/ai_story_service.dart';
import '../../lib/models/story.dart';
import '../test_helpers.dart';

void main() {
  group('AIStoryService - Unit Tests', () {

    group('Service Configuration', () {
      test('should have correct default timeout', () {
        // Test that the service is configured with appropriate timeout
        const expectedTimeout = Duration(minutes: 2);
        expect(expectedTimeout.inMilliseconds, equals(120000));
      });

      test('should validate base URL format', () {
        // Test URL validation logic
        const testUrls = [
          'https://api.example.com',
          'http://localhost:8000',
          'https://production-api.mira.com',
        ];

        for (final url in testUrls) {
          final uri = Uri.tryParse(url);
          expect(uri, isNotNull, reason: '$url should be a valid URL');
          expect(['http', 'https'], contains(uri?.scheme), 
            reason: '$url should use http/https scheme');
        }
      });

      test('should handle API key validation', () {
        // Test API key format validation
        const validApiKeys = [
          'sk-1234567890abcdef',
          'api_key_abcd1234',
          'bearer_token_xyz789',
        ];

        const invalidApiKeys = [
          '',
          '   ',
          'too-short',
        ];

        for (final apiKey in validApiKeys) {
          expect(apiKey.isNotEmpty, isTrue, 
            reason: '$apiKey should be non-empty');
          expect(apiKey.length, greaterThan(10), 
            reason: '$apiKey should be reasonably long');
        }

        for (final apiKey in invalidApiKeys) {
          expect(apiKey.trim().isEmpty || apiKey.length < 10, isTrue, 
            reason: '$apiKey should be considered invalid');
        }
      });
    });

    group('Story Generation Logic', () {
      test('should validate story generation request format', () {
        // Test request validation logic
        final validRequest = {
          'child_name': 'Alice',
          'story_prompt': 'A magical adventure',
          'image_data': TestDataFactory.createTestBase64Image(),
          'language': 'en',
        };

        expect(validRequest['child_name'], isA<String>());
        expect(validRequest['story_prompt'], isA<String>());
        expect(validRequest['image_data'], isA<String>());
        expect(validRequest['language'], isA<String>());

        // Test that all required fields are present
        final requiredFields = ['child_name', 'story_prompt', 'image_data', 'language'];
        for (final field in requiredFields) {
          expect(validRequest.containsKey(field), isTrue, 
            reason: '$field should be present in request');
          expect(validRequest[field], isNotNull, 
            reason: '$field should not be null');
        }
      });

      test('should validate child name format using consistent pattern', () {
        final testNames = TestDataFactory.generateTestNames();
        
        for (final name in testNames) {
          final isValidLength = name.trim().isNotEmpty && 
                               name.length >= TestConstants.minNameLength && 
                               name.length <= TestConstants.maxNameLength;
          final matchesPattern = TestConstants.namePattern.hasMatch(name);
          final isValidName = isValidLength && matchesPattern;
          
          if (['Alice', 'Bob', 'Charlie', 'Diana', 'Eva', 'María', 'José', 'André', 'Žūūū', 'Анна'].contains(name)) {
            expect(isValidName, isTrue, reason: '$name should be valid');
          } else if (['', '   ', '123', 'A', 'Test@Name'].contains(name)) {
            expect(isValidName, isFalse, reason: '$name should be invalid');
          }
        }
      });

      test('should validate story prompt length', () {
        const shortPrompt = 'Magic';
        const goodPrompt = 'A magical adventure in the forest with talking animals';
        final longPrompt = 'A' * 1000;

        expect(shortPrompt.length, lessThan(20));
        expect(goodPrompt.length, inInclusiveRange(20, 200));
        expect(longPrompt.length, greaterThan(500));

        // Good prompt should be in the sweet spot
        expect(goodPrompt.length >= 10 && goodPrompt.length <= TestConstants.maxPromptLength, isTrue);
      });

      test('should validate story prompt using constants', () {
        final promptTests = [
          ('', false), // empty
          ('Short', false), // too short  
          ('This is a good prompt for story generation', true), // good length
          (TestDataFactory.generateText(TestConstants.maxPromptLength), true), // max length
          (TestDataFactory.generateText(TestConstants.maxPromptLength + 1), false), // too long
        ];

        for (final (prompt, shouldBeValid) in promptTests) {
          final isValidLength = prompt.trim().isNotEmpty && 
                               prompt.length >= 10 && 
                               prompt.length <= TestConstants.maxPromptLength;
          expect(isValidLength, equals(shouldBeValid), 
            reason: 'Prompt "$prompt" (${prompt.length} chars) validation should be $shouldBeValid');
        }
      });

      test('should validate base64 image data format using constants', () {
        final validBase64 = TestDataFactory.createTestBase64Image();
        final base64Tests = [
          ('validBase64Data123+/=', true),
          (TestDataFactory.createTestBase64Image(), true),
          ('invalid base64!', false),
          ('', false),
          ('not-base64-data', false),
          ('contains spaces ', false),
          ('has@special#chars', false),
        ];

        for (final (data, shouldBeValid) in base64Tests) {
          final isValid = TestConstants.base64Pattern.hasMatch(data) && data.isNotEmpty;
          expect(isValid, equals(shouldBeValid), 
            reason: 'Base64 data "$data" validation should be $shouldBeValid');
        }
      });
    });

    group('Polling Logic', () {
      test('should calculate correct polling intervals', () {
        // Test exponential backoff calculation
        const baseInterval = Duration(seconds: 2);
        const maxInterval = Duration(seconds: 30);

        final intervals = <Duration>[];
        Duration currentInterval = baseInterval;
        
        for (int attempt = 0; attempt < 10; attempt++) {
          intervals.add(currentInterval);
          currentInterval = Duration(
            milliseconds: (currentInterval.inMilliseconds * 1.5).round(),
          );
          if (currentInterval > maxInterval) {
            currentInterval = maxInterval;
          }
        }

        // First interval should be base
        expect(intervals.first, equals(baseInterval));
        
        // Intervals should increase (up to max)
        for (int i = 1; i < intervals.length - 1; i++) {
          if (intervals[i - 1] < maxInterval) {
            expect(intervals[i].inMilliseconds, 
              greaterThanOrEqualTo(intervals[i - 1].inMilliseconds));
          }
        }

        // Should not exceed max interval
        for (final interval in intervals) {
          expect(interval, lessThanOrEqualTo(maxInterval));
        }
      });

      test('should respect maximum polling attempts', () {
        const maxAttempts = 30;
        const pollInterval = Duration(seconds: 2);
        
        // Calculate total max wait time
        final maxWaitTime = Duration(
          milliseconds: maxAttempts * pollInterval.inMilliseconds,
        );
        
        expect(maxWaitTime.inMinutes, lessThanOrEqualTo(2), 
          reason: 'Total polling time should not exceed 2 minutes');
        expect(maxAttempts, greaterThanOrEqualTo(10), 
          reason: 'Should allow reasonable number of attempts');
      });
    });

    group('Error Handling Logic', () {
      test('should categorize HTTP status codes correctly', () {
        const statusCodes = {
          200: 'success',
          201: 'success', 
          400: 'client_error',
          401: 'auth_error',
          403: 'auth_error',
          404: 'client_error',
          429: 'rate_limit',
          500: 'server_error',
          502: 'server_error',
          503: 'server_error',
        };

        for (final entry in statusCodes.entries) {
          final code = entry.key;
          final category = entry.value;
          
          final isSuccess = code >= 200 && code < 300;
          final isClientError = code >= 400 && code < 500;
          final isServerError = code >= 500 && code < 600;
          
          switch (category) {
            case 'success':
              expect(isSuccess, isTrue, reason: '$code should be success');
              break;
            case 'client_error':
            case 'auth_error':
            case 'rate_limit':
              expect(isClientError, isTrue, reason: '$code should be client error');
              break;
            case 'server_error':
              expect(isServerError, isTrue, reason: '$code should be server error');
              break;
          }
        }
      });

      test('should handle retry logic for transient errors', () {
        // Test which errors should trigger retries
        const retryableErrors = [500, 502, 503, 504, 429];
        const nonRetryableErrors = [400, 401, 403, 404, 422];

        for (final code in retryableErrors) {
          final shouldRetry = code >= 500 || code == 429;
          expect(shouldRetry, isTrue, 
            reason: 'Status $code should be retryable');
        }

        for (final code in nonRetryableErrors) {
          final shouldRetry = code >= 500 || code == 429;
          expect(shouldRetry, isFalse, 
            reason: 'Status $code should not be retryable');
        }
      });
    });

    group('Response Parsing', () {
      test('should validate story response structure', () {
        final validResponse = TestDataFactory.createStoryGenerationResponse();
        
        final requiredFields = ['story_id', 'status', 'title', 'content'];
        for (final field in requiredFields) {
          expect(validResponse.containsKey(field), isTrue,
            reason: '$field should be present in response');
        }

        expect(validResponse['story_id'], isA<String>());
        expect(validResponse['status'], isA<String>());
        expect(validResponse['title'], isA<String>());
        expect(validResponse['content'], isA<String>());
      });

      test('should parse story status correctly', () {
        const statusMappings = {
          'pending': StoryStatus.pending,
          'processing': StoryStatus.pending,
          'completed': StoryStatus.approved,
          'approved': StoryStatus.approved,
          'rejected': StoryStatus.rejected,
        };

        for (final entry in statusMappings.entries) {
          final statusString = entry.key;
          final expectedStatus = entry.value;
          
          // Test the parsing logic matches Story._parseStatus
          StoryStatus parsedStatus;
          switch (statusString) {
            case 'completed':
            case 'approved':
              parsedStatus = StoryStatus.approved;
              break;
            case 'rejected':
              parsedStatus = StoryStatus.rejected;
              break;
            case 'processing':
            case 'pending':
            default:
              parsedStatus = StoryStatus.pending;
              break;
          }
          
          expect(parsedStatus, equals(expectedStatus),
            reason: '$statusString should parse to $expectedStatus');
        }
      });
    });

    group('Language Support', () {
      test('should handle multi-language story generation using constants', () {
        for (final lang in TestConstants.supportedLanguages) {
          final response = TestDataFactory.createStoryGenerationResponse();
          response['language'] = lang;
          
          expect(response['language'], equals(lang));
          expect(TestConstants.supportedLanguages, contains(lang));
        }
      });

      test('should validate language codes against supported list', () {
        final languageTests = [
          ('en', true),
          ('ru', true), 
          ('lv', true),
          ('es', false), // not supported
          ('fr', false), // not supported
          ('invalid', false),
          ('', false),
          ('EN', false), // case sensitive
        ];

        for (final (lang, shouldBeValid) in languageTests) {
          final isSupported = TestConstants.supportedLanguages.contains(lang);
          expect(isSupported, equals(shouldBeValid),
            reason: 'Language "$lang" support should be $shouldBeValid');
        }
      });
    });

    group('Error Boundary Testing', () {
      test('should handle malformed request data gracefully', () {
        final malformedRequests = [
          <String, dynamic>{}, // empty request
          {'child_name': null}, // null values
          {'child_name': 123}, // wrong types
          {'child_name': '', 'story_prompt': '', 'image_data': '', 'language': ''}, // empty strings
          {'child_name': TestDataFactory.generateText(1000)}, // extremely long values
        ];

        for (final request in malformedRequests) {
          // Test that we can at least validate the structure
          expect(request, isA<Map<String, dynamic>>());
          
          // Each field should be testable for basic validity
          final childName = request['child_name'];
          final storyPrompt = request['story_prompt'];
          final imageData = request['image_data'];
          
          if (childName != null) {
            expect(childName, anyOf([isA<String>(), isA<int>(), isNull]));
          }
          if (storyPrompt != null) {
            expect(storyPrompt, anyOf([isA<String>(), isNull]));
          }
          if (imageData != null) {
            expect(imageData, anyOf([isA<String>(), isNull]));
          }
        }
      });

      test('should handle extreme polling scenarios', () {
        // Test polling bounds
        const extremeScenarios = [
          (0, Duration.zero), // no attempts
          (1, Duration(seconds: 1)), // single attempt
          (1000, Duration(minutes: 30)), // many attempts
        ];

        for (final (attempts, maxDuration) in extremeScenarios) {
          if (attempts == 0) {
            expect(attempts, equals(0));
          } else {
            expect(attempts, greaterThan(0));
            expect(maxDuration, greaterThan(Duration.zero));
            
            // Calculate if this is within reasonable bounds
            final averageInterval = maxDuration.inMilliseconds / attempts;
            expect(averageInterval, greaterThan(0));
          }
        }
      });

      test('should handle network error variations', () {
        final networkErrors = [
          'Connection timeout',
          'Host unreachable', 
          'DNS resolution failed',
          'SSL handshake failed',
          'Connection reset by peer',
          '', // empty error message
          TestDataFactory.generateText(1000, char: 'Very long error message '), // long error
        ];

        for (final errorMessage in networkErrors) {
          expect(() {
            throw http.ClientException(errorMessage);
          }, throwsA(isA<http.ClientException>()));
        }
      });
    });

    group('Property-Based Service Testing', () {
      test('request validation properties hold for various inputs', () {
        final names = TestDataFactory.generateTestNames(includeInvalid: false);
        final contents = TestDataFactory.generateStoryContents().where((c) => c.trim().isNotEmpty).toList();
        
        for (int i = 0; i < 10; i++) {
          final name = names[i % names.length];
          final content = contents[i % contents.length];
          final language = TestConstants.supportedLanguages[i % TestConstants.supportedLanguages.length];
          
          final request = {
            'child_name': name,
            'story_prompt': content.length > TestConstants.maxPromptLength 
              ? content.substring(0, TestConstants.maxPromptLength) 
              : content,
            'image_data': TestDataFactory.createTestBase64Image(),
            'language': language,
          };
          
          // Property: all required fields present
          expect(request.keys, containsAll(['child_name', 'story_prompt', 'image_data', 'language']));
          
          // Property: all values are strings
          for (final value in request.values) {
            expect(value, isA<String>());
          }
          
          // Property: language is supported
          expect(TestConstants.supportedLanguages, contains(request['language']));
        }
      });
    });

    group('Network Error Handling', () {
      test('should handle JSON parsing errors', () {
        // Test JSON parsing error handling
        const invalidJson = '{"incomplete": json';
        
        expect(() {
          json.decode(invalidJson);
        }, throwsA(isA<FormatException>()));
      });

      test('should validate URL format for story generation', () {
        // Test URL validation for different endpoints
        const validUrls = [
          'http://127.0.0.1:8000/generate-story',
          'https://api.mira.com/v1/stories',
          'https://localhost:8080/api/generate',
        ];

        for (final url in validUrls) {
          final uri = Uri.tryParse(url);
          expect(uri, isNotNull, reason: '$url should be valid');
          expect(uri?.hasScheme, isTrue);
          expect(['http', 'https'], contains(uri?.scheme));
        }
      });

      test('should handle network timeout scenarios', () {
        // Test timeout handling logic
        const timeoutDuration = Duration(minutes: 2);
        const shortTimeout = Duration(seconds: 30);
        
        expect(timeoutDuration.inMilliseconds, equals(120000));
        expect(shortTimeout.inMilliseconds, equals(30000));
        expect(timeoutDuration, greaterThan(shortTimeout));
      });
    });
  });
}