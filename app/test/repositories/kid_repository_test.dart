import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../lib/repositories/kid_repository.dart';
import '../../lib/models/kid.dart';
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

void main() {
  group('KidRepository Unit Tests', () {
    late KidRepository repository;
    late FakeHttpClient fakeHttpClient;
    
    setUp(() {
      fakeHttpClient = FakeHttpClient();
      
      repository = KidRepository(
        httpClient: fakeHttpClient,
      );
      
      KidRepository.clearCache();
    });

    group('getKidsForUser', () {
      test('returns kids from API successfully', () async {
        // Arrange
        const userId = 'test-user-123';
        final testKids = [
          TestHelpers.createTestKid(id: 'kid-1', name: 'Alice', age: 7),
          TestHelpers.createTestKid(id: 'kid-2', name: 'Bob', age: 5),
        ];
        
        final responseBody = json.encode({
          'kids': testKids.map((kid) => {
            'id': kid.id,
            'user_id': kid.userId,
            'name': kid.name,
            'age': kid.age,
            'gender': kid.gender,
            'avatar_type': kid.avatarType,
            'appearance_description': kid.appearanceDescription,
            'favorite_genres': kid.favoriteGenres,
            'parent_notes': kid.parentNotes,
            'preferred_language': kid.preferredLanguage,
            'created_at': kid.createdAt.toIso8601String(),
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/user/$userId',
          http.Response(responseBody, 200)
        );

        // Act
        final result = await repository.getKidsForUser(userId);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, equals('kid-1'));
        expect(result[0].name, equals('Alice'));
        expect(result[0].age, equals(7));
        expect(result[1].id, equals('kid-2'));
        expect(result[1].name, equals('Bob'));
        expect(result[1].age, equals(5));
        
        // Verify request was made
        expect(fakeHttpClient.requests, hasLength(1));
        expect(fakeHttpClient.requests[0].url.toString(), 
            contains('/kids/user/$userId'));
      });

      test('returns cached kids when available', () async {
        // Arrange
        const userId = 'test-user-123';
        final testKids = [
          TestHelpers.createTestKid(id: 'cached-kid', name: 'Cached Kid'),
        ];
        
        final responseBody = json.encode({
          'kids': testKids.map((kid) => {
            'id': kid.id,
            'user_id': kid.userId,
            'name': kid.name,
            'age': kid.age,
            'gender': kid.gender,
            'avatar_type': kid.avatarType,
            'appearance_description': kid.appearanceDescription,
            'favorite_genres': kid.favoriteGenres,
            'parent_notes': kid.parentNotes,
            'preferred_language': kid.preferredLanguage,
            'created_at': kid.createdAt.toIso8601String(),
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/user/$userId',
          http.Response(responseBody, 200)
        );

        // First call to populate cache
        await repository.getKidsForUser(userId);
        
        // Clear requests to verify cache usage
        fakeHttpClient.requests.clear();

        // Act - Second call should use cache
        final result = await repository.getKidsForUser(userId);

        // Assert
        expect(result, hasLength(1));
        expect(result[0].id, equals('cached-kid'));
        
        // Should not make additional HTTP calls (cache hit)
        expect(fakeHttpClient.requests, isEmpty);
      });

      test('handles HTTP errors gracefully', () async {
        // Arrange
        const userId = 'test-user-123';
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/user/$userId',
          http.Response('Not found', 404)
        );

        // Act & Assert
        expect(
          () => repository.getKidsForUser(userId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to fetch kids: 404'),
          )),
        );
      });

      test('returns expired cache data when API call fails', () async {
        // Arrange
        const userId = 'test-user-123';
        final testKids = [
          TestHelpers.createTestKid(id: 'cached-kid', name: 'Cached Kid'),
        ];
        
        final responseBody = json.encode({
          'kids': testKids.map((kid) => {
            'id': kid.id,
            'user_id': kid.userId,
            'name': kid.name,
            'age': kid.age,
            'gender': kid.gender,
            'avatar_type': kid.avatarType,
            'appearance_description': kid.appearanceDescription,
            'favorite_genres': kid.favoriteGenres,
            'parent_notes': kid.parentNotes,
            'preferred_language': kid.preferredLanguage,
            'created_at': kid.createdAt.toIso8601String(),
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/user/$userId',
          http.Response(responseBody, 200)
        );

        // Populate cache
        await repository.getKidsForUser(userId);
        
        // Make subsequent call fail
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/user/$userId',
          http.Response('Server error', 500)
        );

        // Act
        final result = await repository.getKidsForUser(userId);

        // Assert - should return cached data even though API failed
        expect(result, hasLength(1));
        expect(result[0].id, equals('cached-kid'));
      });
    });

    group('createKid', () {
      test('creates kid successfully', () async {
        // Arrange
        const userId = 'test-user-123';
        const name = 'New Kid';
        const age = 6;
        final createdKid = TestHelpers.createTestKid(
          id: 'new-kid-123', 
          userId: userId,
          name: name, 
          age: age
        );
        
        final responseBody = json.encode({
          'kid': {
            'id': createdKid.id,
            'user_id': createdKid.userId,
            'name': createdKid.name,
            'age': createdKid.age,
            'gender': createdKid.gender,
            'avatar_type': createdKid.avatarType,
            'appearance_description': createdKid.appearanceDescription,
            'favorite_genres': createdKid.favoriteGenres,
            'parent_notes': createdKid.parentNotes,
            'preferred_language': createdKid.preferredLanguage,
            'created_at': createdKid.createdAt.toIso8601String(),
          }
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids',
          http.Response(responseBody, 201)
        );

        // Act
        final result = await repository.createKid(
          userId: userId,
          name: name,
          age: age,
        );

        // Assert
        expect(result.id, equals('new-kid-123'));
        expect(result.name, equals(name));
        expect(result.age, equals(age));
        expect(result.userId, equals(userId));
        
        // Verify POST request was made
        expect(fakeHttpClient.requests, hasLength(1));
        expect(fakeHttpClient.requests[0].method, equals('POST'));
        expect(fakeHttpClient.requests[0].url.toString(), 
            contains('/kids'));
      });

      test('creates kid with all optional parameters', () async {
        // Arrange
        const userId = 'test-user-123';
        const name = 'Full Kid';
        const age = 8;
        const gender = 'girl';
        const avatarType = 'profile2';
        const favoriteGenres = ['fantasy', 'adventure'];
        const parentNotes = 'Test notes';
        const preferredLanguage = 'es';
        
        final createdKid = TestHelpers.createTestKid(
          id: 'full-kid-123',
          userId: userId,
          name: name,
          age: age,
          gender: gender,
          avatarType: avatarType,
          favoriteGenres: favoriteGenres,
          parentNotes: parentNotes,
          preferredLanguage: preferredLanguage,
        );
        
        final responseBody = json.encode({
          'kid': {
            'id': createdKid.id,
            'user_id': createdKid.userId,
            'name': createdKid.name,
            'age': createdKid.age,
            'gender': createdKid.gender,
            'avatar_type': createdKid.avatarType,
            'appearance_description': createdKid.appearanceDescription,
            'favorite_genres': createdKid.favoriteGenres,
            'parent_notes': createdKid.parentNotes,
            'preferred_language': createdKid.preferredLanguage,
            'created_at': createdKid.createdAt.toIso8601String(),
          }
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids',
          http.Response(responseBody, 201)
        );

        // Act
        final result = await repository.createKid(
          userId: userId,
          name: name,
          age: age,
          gender: gender,
          avatarType: avatarType,
          favoriteGenres: favoriteGenres,
          parentNotes: parentNotes,
          preferredLanguage: preferredLanguage,
        );

        // Assert
        expect(result.name, equals(name));
        expect(result.age, equals(age));
        expect(result.gender, equals(gender));
        expect(result.avatarType, equals(avatarType));
        expect(result.favoriteGenres, equals(favoriteGenres));
        expect(result.parentNotes, equals(parentNotes));
        expect(result.preferredLanguage, equals(preferredLanguage));
      });

      test('handles creation errors gracefully', () async {
        // Arrange
        const userId = 'test-user-123';
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids',
          http.Response('Bad request', 400)
        );

        // Act & Assert
        expect(
          () => repository.createKid(userId: userId, name: 'Test Kid', age: 5),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to create kid: 400'),
          )),
        );
      });
    });

    group('updateKid', () {
      test('updates kid successfully', () async {
        // Arrange
        const kidId = 'test-kid-123';
        const updatedName = 'Updated Kid';
        const updatedAge = 8;
        
        final updatedKid = TestHelpers.createTestKid(
          id: kidId,
          name: updatedName,
          age: updatedAge,
        );
        
        final responseBody = json.encode({
          'kid': {
            'id': updatedKid.id,
            'user_id': updatedKid.userId,
            'name': updatedKid.name,
            'age': updatedKid.age,
            'gender': updatedKid.gender,
            'avatar_type': updatedKid.avatarType,
            'appearance_description': updatedKid.appearanceDescription,
            'favorite_genres': updatedKid.favoriteGenres,
            'parent_notes': updatedKid.parentNotes,
            'preferred_language': updatedKid.preferredLanguage,
            'created_at': updatedKid.createdAt.toIso8601String(),
          }
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/$kidId',
          http.Response(responseBody, 200)
        );

        // Act
        final result = await repository.updateKid(
          kidId: kidId,
          name: updatedName,
          age: updatedAge,
        );

        // Assert
        expect(result.id, equals(kidId));
        expect(result.name, equals(updatedName));
        expect(result.age, equals(updatedAge));
        
        // Verify PUT request was made
        expect(fakeHttpClient.requests, hasLength(1));
        expect(fakeHttpClient.requests[0].method, equals('PUT'));
        expect(fakeHttpClient.requests[0].url.toString(), 
            contains('/kids/$kidId'));
      });

      test('handles update errors gracefully', () async {
        // Arrange
        const kidId = 'nonexistent-kid';
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/$kidId',
          http.Response('Not found', 404)
        );

        // Act & Assert
        expect(
          () => repository.updateKid(kidId: kidId, name: 'Test', age: 5),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to update kid: 404'),
          )),
        );
      });
    });

    group('deleteKid', () {
      test('deletes kid successfully', () async {
        // Arrange
        const kidId = 'test-kid-123';
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/$kidId',
          http.Response('', 204)
        );

        // Act
        await repository.deleteKid(kidId);

        // Verify DELETE request was made
        expect(fakeHttpClient.requests, hasLength(1));
        expect(fakeHttpClient.requests[0].method, equals('DELETE'));
        expect(fakeHttpClient.requests[0].url.toString(), 
            contains('/kids/$kidId'));
      });

      test('handles deletion errors gracefully', () async {
        // Arrange
        const kidId = 'nonexistent-kid';
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/$kidId',
          http.Response('Not found', 404)
        );

        // Act & Assert
        expect(
          () => repository.deleteKid(kidId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete kid: 404'),
          )),
        );
      });
    });

    group('Cache Management', () {
      test('clearCache removes all cached data', () async {
        // Arrange
        const userId = 'test-user-123';
        final testKids = [
          TestHelpers.createTestKid(id: 'kid-1', name: 'Kid 1'),
        ];
        
        final responseBody = json.encode({
          'kids': testKids.map((kid) => {
            'id': kid.id,
            'user_id': kid.userId,
            'name': kid.name,
            'age': kid.age,
            'gender': kid.gender,
            'avatar_type': kid.avatarType,
            'appearance_description': kid.appearanceDescription,
            'favorite_genres': kid.favoriteGenres,
            'parent_notes': kid.parentNotes,
            'preferred_language': kid.preferredLanguage,
            'created_at': kid.createdAt.toIso8601String(),
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/user/$userId',
          http.Response(responseBody, 200)
        );

        // Populate cache
        await repository.getKidsForUser(userId);
        fakeHttpClient.requests.clear();

        // Act
        KidRepository.clearCache();

        // Assert - Should make new HTTP call since cache is cleared
        await repository.getKidsForUser(userId);
        expect(fakeHttpClient.requests, hasLength(1));
      });

      test('clearUserCache removes cache for specific user', () async {
        // Arrange
        const userId = 'test-user-123';
        final testKids = [
          TestHelpers.createTestKid(id: 'kid-1', name: 'Kid 1'),
        ];
        
        final responseBody = json.encode({
          'kids': testKids.map((kid) => {
            'id': kid.id,
            'user_id': kid.userId,
            'name': kid.name,
            'age': kid.age,
            'gender': kid.gender,
            'avatar_type': kid.avatarType,
            'appearance_description': kid.appearanceDescription,
            'favorite_genres': kid.favoriteGenres,
            'parent_notes': kid.parentNotes,
            'preferred_language': kid.preferredLanguage,
            'created_at': kid.createdAt.toIso8601String(),
          }).toList()
        });
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/user/$userId',
          http.Response(responseBody, 200)
        );

        // Populate cache
        await repository.getKidsForUser(userId);
        fakeHttpClient.requests.clear();

        // Act
        repository.clearUserCache(userId);

        // Assert - Should make new HTTP call since cache is cleared
        await repository.getKidsForUser(userId);
        expect(fakeHttpClient.requests, hasLength(1));
      });
    });

    group('Error Handling', () {
      test('handles JSON parsing errors gracefully', () async {
        // Arrange
        const userId = 'test-user-123';
        
        fakeHttpClient.setResponse(
          '${ApiConstants.baseUrl}/kids/user/$userId',
          http.Response('Invalid JSON', 200)
        );

        // Act & Assert
        expect(
          () => repository.getKidsForUser(userId),
          throwsA(isA<FormatException>()),
        );
      });

      test('handles network errors gracefully', () async {
        // Arrange
        const userId = 'test-user-123';
        
        // Don't set any response to simulate network failure
        // This will trigger the default 404 response in FakeHttpClient
        
        // Act & Assert
        expect(
          () => repository.getKidsForUser(userId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to fetch kids: 404'),
          )),
        );
      });
    });
  });
}