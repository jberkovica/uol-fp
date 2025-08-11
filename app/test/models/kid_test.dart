import 'package:flutter_test/flutter_test.dart';
import 'package:mira_storyteller/models/kid.dart';
import '../test_helpers.dart';

void main() {
  group('Kid Model Tests', () {
    group('Construction', () {
      test('should create Kid with all required fields', () {
        final kid = Kid(
          id: 'test-id',
          userId: 'user-123',
          name: 'Alice',
          age: 7,
          gender: 'girl',
          avatarType: 'profile1',
          createdAt: DateTime.now(),
        );

        expect(kid.id, equals('test-id'));
        expect(kid.name, equals('Alice'));
        expect(kid.age, equals(7));
        expect(kid.gender, equals('girl'));
        expect(kid.avatarType, equals('profile1'));
      });

      test('should create Kid with optional appearance fields', () {
        final kid = Kid(
          id: 'test-id',
          userId: 'user-123',
          name: 'Bob',
          age: 8,
          gender: 'boy',
          avatarType: 'profile2',
          appearanceMethod: 'photo',
          appearanceDescription: 'Brown curly hair, blue eyes',
          favoriteGenres: ['adventure', 'fantasy'],
          parentNotes: 'Loves superhero stories',
          preferredLanguage: 'en',
          createdAt: DateTime.now(),
        );

        expect(kid.appearanceMethod, equals('photo'));
        expect(kid.appearanceDescription, equals('Brown curly hair, blue eyes'));
        expect(kid.favoriteGenres, equals(['adventure', 'fantasy']));
        expect(kid.parentNotes, equals('Loves superhero stories'));
        expect(kid.preferredLanguage, equals('en'));
      });

      test('should handle null optional fields', () {
        final kid = Kid(
          id: 'test-id',
          userId: 'user-123',
          name: 'Charlie',
          age: 5,
          avatarType: 'profile3',
          createdAt: DateTime.now(),
        );

        expect(kid.gender, isNull);
        expect(kid.appearanceMethod, isNull);
        expect(kid.appearanceDescription, isNull);
        expect(kid.parentNotes, isNull);
        expect(kid.favoriteGenres, isEmpty);
        expect(kid.preferredLanguage, equals('en')); // default value
      });
    });

    group('Gender Validation', () {
      test('should accept valid gender values', () {
        const validGenders = ['boy', 'girl', 'other'];
        
        for (final gender in validGenders) {
          final kid = TestHelpers.createTestKid(gender: gender);
          expect(kid.gender, equals(gender));
        }
      });

      test('should accept null gender', () {
        // Create kid directly to avoid default gender in test helper
        final kid = Kid(
          id: 'test-id',
          userId: 'user-123',
          name: 'Test',
          age: 7,
          avatarType: 'profile1',
          createdAt: DateTime.now(),
        );
        expect(kid.gender, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final kid = Kid(
          id: 'test-id',
          userId: 'user-123',
          name: 'Alice',
          age: 7,
          gender: 'girl',
          avatarType: 'profile1',
          appearanceMethod: 'manual',
          appearanceDescription: 'Brown hair, green eyes',
          favoriteGenres: ['fantasy', 'adventure'],
          parentNotes: 'Loves princess stories',
          preferredLanguage: 'en',
          createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
        );

        final json = kid.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['name'], equals('Alice'));
        expect(json['age'], equals(7));
        expect(json['gender'], equals('girl'));
        expect(json['appearance_method'], equals('manual'));
        expect(json['appearance_description'], equals('Brown hair, green eyes'));
        expect(json['favorite_genres'], equals(['fantasy', 'adventure']));
        expect(json['parent_notes'], equals('Loves princess stories'));
        expect(json['preferred_language'], equals('en'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-123',
          'name': 'Bob',
          'age': 8,
          'gender': 'boy',
          'avatar_type': 'profile2',
          'appearance_method': 'photo',
          'appearance_description': 'Blonde hair, blue eyes',
          'favorite_genres': ['adventure', 'mystery'],
          'parent_notes': 'Enjoys detective stories',
          'preferred_language': 'ru',
          'created_at': '2024-01-01T12:00:00Z',
        };

        final kid = Kid.fromJson(json);

        expect(kid.id, equals('test-id'));
        expect(kid.userId, equals('user-123'));
        expect(kid.name, equals('Bob'));
        expect(kid.age, equals(8));
        expect(kid.gender, equals('boy'));
        expect(kid.avatarType, equals('profile2'));
        expect(kid.appearanceMethod, equals('photo'));
        expect(kid.appearanceDescription, equals('Blonde hair, blue eyes'));
        expect(kid.favoriteGenres, equals(['adventure', 'mystery']));
        expect(kid.parentNotes, equals('Enjoys detective stories'));
        expect(kid.preferredLanguage, equals('ru'));
      });

      test('should handle missing optional fields in JSON', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-123',
          'name': 'Emma',
          'age': 6,
          'avatar_type': 'profile1',
          'created_at': '2024-01-01T12:00:00Z',
        };

        final kid = Kid.fromJson(json);

        expect(kid.gender, isNull);
        expect(kid.appearanceMethod, isNull);
        expect(kid.appearanceDescription, isNull);
        expect(kid.parentNotes, isNull);
        expect(kid.favoriteGenres, isEmpty);
        expect(kid.preferredLanguage, equals('en')); // default
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final originalKid = TestHelpers.createTestKid(
          name: 'Alice',
          age: 7,
          gender: 'girl',
        );

        final updatedKid = originalKid.copyWith(
          name: 'Alicia',
          age: 8,
          gender: 'other',
        );

        expect(updatedKid.name, equals('Alicia'));
        expect(updatedKid.age, equals(8));
        expect(updatedKid.gender, equals('other'));
        expect(updatedKid.id, equals(originalKid.id)); // unchanged
      });

      test('should preserve unchanged fields in copy', () {
        final originalKid = TestHelpers.createTestKid(
          name: 'Bob',
          appearanceDescription: 'Original description',
          favoriteGenres: ['adventure'],
        );

        final updatedKid = originalKid.copyWith(age: 9);

        expect(updatedKid.age, equals(9)); // changed
        expect(updatedKid.name, equals('Bob')); // unchanged
        expect(updatedKid.appearanceDescription, equals('Original description')); // unchanged
        expect(updatedKid.favoriteGenres, equals(['adventure'])); // unchanged
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all fields match', () {
        final kid1 = TestHelpers.createTestKid(
          id: 'same-id',
          name: 'Alice',
          age: 7,
          gender: 'girl',
        );

        final kid2 = TestHelpers.createTestKid(
          id: 'same-id',
          name: 'Alice', 
          age: 7,
          gender: 'girl',
        );

        expect(kid1, equals(kid2));
        expect(kid1.hashCode, equals(kid2.hashCode));
      });

      test('should not be equal when key fields differ', () {
        final kid1 = TestHelpers.createTestKid(id: 'id-1', name: 'Alice');
        final kid2 = TestHelpers.createTestKid(id: 'id-2', name: 'Alice');

        expect(kid1, isNot(equals(kid2)));
        expect(kid1.hashCode, isNot(equals(kid2.hashCode)));
      });

      test('should not be equal when gender differs', () {
        final kid1 = TestHelpers.createTestKid(id: 'same-id', gender: 'boy');
        final kid2 = TestHelpers.createTestKid(id: 'same-id', gender: 'girl');

        expect(kid1, isNot(equals(kid2)));
      });
    });

    group('Appearance System', () {
      test('should support manual appearance method', () {
        final kid = TestHelpers.createTestKid(
          appearanceMethod: 'manual',
          appearanceDescription: 'Tall, dark hair, brown eyes',
        );

        expect(kid.appearanceMethod, equals('manual'));
        expect(kid.appearanceDescription, equals('Tall, dark hair, brown eyes'));
      });

      test('should support photo appearance method', () {
        final kid = TestHelpers.createTestKid(
          appearanceMethod: 'photo',
          appearanceDescription: 'AI extracted: Curly red hair, freckles',
        );

        expect(kid.appearanceMethod, equals('photo'));
        expect(kid.appearanceDescription, contains('AI extracted'));
      });

      test('should handle no appearance method set', () {
        final kid = TestHelpers.createTestKid();

        expect(kid.appearanceMethod, isNull);
        expect(kid.appearanceDescription, isNotNull); // default from helper
      });
    });

    group('Story Preferences', () {
      test('should store favorite genres correctly', () {
        final genres = ['fantasy', 'adventure', 'mystery', 'animals'];
        final kid = TestHelpers.createTestKid(favoriteGenres: genres);

        expect(kid.favoriteGenres, equals(genres));
      });

      test('should handle empty favorite genres', () {
        final kid = TestHelpers.createTestKid(favoriteGenres: []);

        expect(kid.favoriteGenres, isEmpty);
      });

      test('should store parent notes', () {
        const notes = 'Child loves stories about brave animals and friendship. Avoid scary themes.';
        final kid = TestHelpers.createTestKid(parentNotes: notes);

        expect(kid.parentNotes, equals(notes));
      });

      test('should handle different preferred languages', () {
        const languages = ['en', 'ru', 'lv', 'es'];
        
        for (final lang in languages) {
          final kid = TestHelpers.createTestKid(preferredLanguage: lang);
          expect(kid.preferredLanguage, equals(lang));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle very long names within limits', () {
        final longName = 'A' * 49; // Just under 50 char limit
        final kid = TestHelpers.createTestKid(name: longName);

        expect(kid.name, equals(longName));
        expect(kid.name.length, lessThanOrEqualTo(50));
      });

      test('should handle age boundaries', () {
        final youngKid = TestHelpers.createTestKid(age: 3); // minimum age
        final oldKid = TestHelpers.createTestKid(age: 12); // maximum age

        expect(youngKid.age, equals(3));
        expect(oldKid.age, equals(12));
      });

      test('should handle special characters in descriptions', () {
        const specialDescription = 'Has émojis 🌟 and "quotes" & symbols!';
        final kid = TestHelpers.createTestKid(appearanceDescription: specialDescription);

        expect(kid.appearanceDescription, equals(specialDescription));
      });

      test('should handle international names', () {
        const internationalNames = ['José', 'María', 'André', 'Žūūū', 'Анна'];
        
        for (final name in internationalNames) {
          final kid = TestHelpers.createTestKid(name: name);
          expect(kid.name, equals(name));
        }
      });
    });
  });
}