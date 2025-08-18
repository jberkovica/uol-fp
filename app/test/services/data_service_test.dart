import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/data_service.dart';
import '../test_helpers.dart';

void main() {
  group('DataService Unit Tests', () {
    late DataService dataService;
    
    setUp(() {
      // Use the real DataService but control its state
      dataService = DataService();
    });

    tearDown(() {
      // Clean up after each test
      dataService.dispose();
    });

    group('Initialization', () {
      test('initializes with user ID successfully', () {
        // Act
        dataService.initialize('test-user-123');

        // Assert
        expect(dataService.currentUserId, equals('test-user-123'));
      });

      test('currentUserId returns null when not initialized', () {
        // Assert
        expect(dataService.currentUserId, isNull);
      });

      test('dispose clears user ID', () {
        // Arrange
        dataService.initialize('test-user-123');
        expect(dataService.currentUserId, equals('test-user-123'));

        // Act
        dataService.dispose();

        // Assert
        expect(dataService.currentUserId, isNull);
      });
    });

    group('Kid Operations', () {
      test('getKidsForCurrentUser returns empty list when no user is set', () async {
        // Act
        final result = await dataService.getKidsForCurrentUser();

        // Assert
        expect(result, isEmpty);
      });

      test('getKidsStream returns empty stream when no user is set', () async {
        // Act
        final stream = dataService.getKidsStream();
        final result = await stream.first;

        // Assert
        expect(result, isEmpty);
      });

      test('createKid throws exception when no user is set', () async {
        // Act & Assert
        expect(
          () => dataService.createKid(name: 'Test Kid', age: 5),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No current user ID set'),
          )),
        );
      });
    });

    group('Cache Management', () {
      test('clearAllCache executes without error', () {
        // Act & Assert
        expect(() => dataService.clearAllCache(), returnsNormally);
      });

      test('clearStoryCache executes without error', () {
        // Act & Assert
        expect(() => dataService.clearStoryCache('test-kid'), returnsNormally);
      });

      test('clearKidCache executes without error', () {
        // Act & Assert
        expect(() => dataService.clearKidCache(), returnsNormally);
      });
    });

    group('Story Operations', () {
      test('story operations exist and are callable', () {
        // These tests verify that the DataService methods exist and can be called
        // The actual repository functionality is tested in repository tests
        
        // Just verify the methods exist without calling them (to avoid Supabase dependencies)
        expect(dataService.getStoriesForKid, isA<Function>());
        expect(dataService.getStoriesStream, isA<Function>());
        expect(dataService.getStoryById, isA<Function>());
        expect(dataService.toggleStoryFavorite, isA<Function>());
      });
    });

    group('Integration Tests', () {
      test('service initialization and disposal workflow', () {
        // Test 1: Service starts uninitialized
        expect(dataService.currentUserId, isNull);
        
        // Test 2: Initialize with user
        dataService.initialize('user-123');
        expect(dataService.currentUserId, equals('user-123'));
        
        // Test 3: Can reinitialize with different user
        dataService.initialize('user-456');
        expect(dataService.currentUserId, equals('user-456'));
        
        // Test 4: Dispose clears state
        dataService.dispose();
        expect(dataService.currentUserId, isNull);
      });

      test('kid operations require user initialization', () async {
        // Verify all kid operations return empty/throw when no user set
        expect(await dataService.getKidsForCurrentUser(), isEmpty);
        expect(await dataService.getKidsStream().first, isEmpty);
        
        await expectLater(
          () => dataService.createKid(name: 'Test', age: 5),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message', 
            contains('No current user ID set'),
          )),
        );
      });
    });
  });
}