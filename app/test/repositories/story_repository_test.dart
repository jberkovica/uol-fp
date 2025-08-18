import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/repositories/story_repository.dart';
import '../../lib/models/story.dart';
import '../../lib/constants/api_constants.dart';
import '../test_helpers.dart';

// Create fake HTTP client for testing
class FakeHttpClient extends http.BaseClient {
  final Map<String, http.Response> responses = {};
  final List<http.BaseRequest> requests = [];
  
  void setResponse(String url, http.Response response) {
    responses[url] = response;
  }
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = responses[request.url.toString()];
    
    if (response != null) {
      return http.StreamedResponse(
        Stream.fromIterable([response.bodyBytes]),
        response.statusCode,
        headers: response.headers,
      );
    }
    
    // Default 404 response
    return http.StreamedResponse(
      Stream.fromIterable([]),
      404,
    );
  }
}

// Fake Supabase client for testing
class FakeSupabaseClient implements SupabaseClient {
  @override
  noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('StoryRepository Unit Tests', () {
    late StoryRepository repository;
    late FakeHttpClient fakeHttpClient;
    late FakeSupabaseClient fakeSupabaseClient;
    
    setUp(() {
      fakeHttpClient = FakeHttpClient();
      fakeSupabaseClient = FakeSupabaseClient();
      
      repository = StoryRepository(
        httpClient: fakeHttpClient,
        supabaseClient: fakeSupabaseClient,
      );
      
      StoryRepository.clearCache();
    });

    tearDown(() {
      repository.dispose();
    });

    group('getStoriesForKid', () {
      test('returns stories from API successfully', () async {
        // Arrange
        const kidId = 'test-kid-123';
        final testStories = [
          TestHelpers.createTestStory(id: 'story-1', title: 'Story 1'),
          TestHelpers.createTestStory(id: 'story-2', title: 'Story 2'),
        ];
        
        final responseBody = json.encode({
          'stories': testStories.map((story) => {
            'id': story.id,
            'title': story.title,
            'content': story.content,
            'status': story.status.toString().split('.').last,
            'child_name': story.childName,
            'created_at': story.createdAt.toIso8601String(),
            'is_favourite': story.isFavourite,
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/stories/kid/$kidId',
          http.Response(responseBody, 200)
        );

        // Act
        final result = await repository.getStoriesForKid(kidId);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, equals('story-1'));
        expect(result[0].title, equals('Story 1'));
        expect(result[1].id, equals('story-2'));
        expect(result[1].title, equals('Story 2'));
        
        // Verify request was made
        expect(fakeHttpClient.requests, hasLength(1));
        expect(fakeHttpClient.requests[0].url.toString(), 
            contains('/stories/kid/$kidId'));
      });

      test('handles HTTP errors gracefully', () async {
        // Arrange
        const kidId = 'test-kid-123';
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/stories/kid/$kidId',
          http.Response('Not found', 404)
        );

        // Act & Assert
        expect(
          () => repository.getStoriesForKid(kidId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to fetch stories: 404'),
          )),
        );
      });

      test('returns cached data when available', () async {
        // Arrange
        const kidId = 'test-kid-123';
        final testStories = [
          TestHelpers.createTestStory(id: 'cached-story', title: 'Cached Story'),
        ];
        
        final responseBody = json.encode({
          'stories': testStories.map((story) => {
            'id': story.id,
            'title': story.title,
            'content': story.content,
            'status': story.status.toString().split('.').last,
            'child_name': story.childName,
            'created_at': story.createdAt.toIso8601String(),
            'is_favourite': story.isFavourite,
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/stories/kid/$kidId',
          http.Response(responseBody, 200)
        );

        // First call to populate cache
        await repository.getStoriesForKid(kidId);
        
        // Clear requests to verify cache usage
        fakeHttpClient.requests.clear();

        // Act - Second call should use cache
        final result = await repository.getStoriesForKid(kidId);

        // Assert
        expect(result, hasLength(1));
        expect(result[0].id, equals('cached-story'));
        
        // Should not make additional HTTP calls (cache hit)
        expect(fakeHttpClient.requests, isEmpty);
      });
    });

    group('getStoryById', () {
      test('returns single story successfully', () async {
        // Arrange
        const storyId = 'test-story-123';
        final testStory = TestHelpers.createTestStory(id: storyId, title: 'Test Story');
        
        final responseBody = json.encode({
          'id': testStory.id,
          'title': testStory.title,
          'content': testStory.content,
          'status': testStory.status.toString().split('.').last,
          'child_name': testStory.childName,
          'created_at': testStory.createdAt.toIso8601String(),
          'is_favourite': testStory.isFavourite,
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/stories/$storyId',
          http.Response(responseBody, 200)
        );

        // Act
        final result = await repository.getStoryById(storyId);

        // Assert
        expect(result.id, equals(storyId));
        expect(result.title, equals('Test Story'));
        
        // Verify request was made
        expect(fakeHttpClient.requests, hasLength(1));
        expect(fakeHttpClient.requests[0].url.toString(), 
            contains('/stories/$storyId'));
      });
    });

    group('toggleStoryFavorite', () {
      test('toggles favorite status successfully', () async {
        // Arrange
        const storyId = 'test-story-123';
        const isFavorite = true;
        final updatedStory = TestHelpers.createTestStory(
          id: storyId,
          title: 'Updated Story',
          isFavourite: isFavorite,
        );
        
        final responseBody = json.encode({
          'id': updatedStory.id,
          'title': updatedStory.title,
          'content': updatedStory.content,
          'status': updatedStory.status.toString().split('.').last,
          'child_name': updatedStory.childName,
          'created_at': updatedStory.createdAt.toIso8601String(),
          'is_favourite': updatedStory.isFavourite,
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/stories/$storyId/favourite',
          http.Response(responseBody, 200)
        );

        // Act
        final result = await repository.toggleStoryFavorite(storyId, isFavorite);

        // Assert
        expect(result.id, equals(storyId));
        expect(result.isFavourite, equals(isFavorite));
        
        // Verify PUT request was made
        expect(fakeHttpClient.requests, hasLength(1));
        expect(fakeHttpClient.requests[0].method, equals('PUT'));
        expect(fakeHttpClient.requests[0].url.toString(), 
            contains('/stories/$storyId/favourite'));
      });
    });

    group('Cache Management', () {
      test('clearCache removes all cached data', () async {
        // Arrange
        const kidId = 'test-kid-123';
        final testStories = [
          TestHelpers.createTestStory(id: 'story-1', title: 'Story 1'),
        ];
        
        final responseBody = json.encode({
          'stories': testStories.map((story) => {
            'id': story.id,
            'title': story.title,
            'content': story.content,
            'status': story.status.toString().split('.').last,
            'child_name': story.childName,
            'created_at': story.createdAt.toIso8601String(),
            'is_favourite': story.isFavourite,
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/stories/kid/$kidId',
          http.Response(responseBody, 200)
        );

        // Populate cache
        await repository.getStoriesForKid(kidId);
        fakeHttpClient.requests.clear();

        // Act
        StoryRepository.clearCache();

        // Assert - Should make new HTTP call since cache is cleared
        await repository.getStoriesForKid(kidId);
        expect(fakeHttpClient.requests, hasLength(1));
      });

      test('clearKidCache removes cache for specific kid', () async {
        // Arrange
        const kidId = 'test-kid-123';
        final testStories = [
          TestHelpers.createTestStory(id: 'story-1', title: 'Story 1'),
        ];
        
        final responseBody = json.encode({
          'stories': testStories.map((story) => {
            'id': story.id,
            'title': story.title,
            'content': story.content,
            'status': story.status.toString().split('.').last,
            'child_name': story.childName,
            'created_at': story.createdAt.toIso8601String(),
            'is_favourite': story.isFavourite,
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/stories/kid/$kidId',
          http.Response(responseBody, 200)
        );

        // Populate cache
        await repository.getStoriesForKid(kidId);
        fakeHttpClient.requests.clear();

        // Act
        repository.clearKidCache(kidId);

        // Assert - Should make new HTTP call since cache is cleared
        await repository.getStoriesForKid(kidId);
        expect(fakeHttpClient.requests, hasLength(1));
      });
    });

    group('Error Handling', () {
      test('handles JSON parsing errors gracefully', () async {
        // Arrange
        const kidId = 'test-kid-123';
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/stories/kid/$kidId',
          http.Response('Invalid JSON', 200)
        );

        // Act & Assert
        expect(
          () => repository.getStoriesForKid(kidId),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}