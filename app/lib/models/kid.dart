import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Kid model representing a child profile with natural language appearance system
class Kid {
  final String id;
  final String userId;
  final String name;
  final int age; // Now mandatory for age-appropriate content
  final String? gender; // 'boy', 'girl', or 'other'
  final String avatarType;
  
  // Natural Language Appearance System
  final String? appearanceMethod; // 'photo', 'manual', or null
  final String? appearanceDescription; // Natural language description
  final DateTime? appearanceExtractedAt; // When extracted from photo
  final Map<String, dynamic>? appearanceMetadata; // AI extraction details
  
  // Story Preferences
  final List<String> favoriteGenres;
  final String? parentNotes; // Special context for stories
  final String preferredLanguage; // Child's preferred language
  
  final DateTime createdAt;

  const Kid({
    required this.id,
    required this.userId,
    required this.name,
    required this.age, // Now required
    this.gender,
    required this.avatarType,
    this.appearanceMethod,
    this.appearanceDescription,
    this.appearanceExtractedAt,
    this.appearanceMetadata,
    this.favoriteGenres = const [],
    this.parentNotes,
    this.preferredLanguage = 'en',
    required this.createdAt,
  });

  factory Kid.fromJson(Map<String, dynamic> json) {
    List<String> genres = [];
    final genresData = json['favorite_genres'];
    if (genresData != null) {
      if (genresData is List) {
        genres = genresData.map((e) => e.toString()).toList();
      } else if (genresData is String) {
        // Handle case where it might come as a JSON string
        try {
          final decoded = jsonDecode(genresData);
          if (decoded is List) {
            genres = decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // Log error and continue with empty genres list
          debugPrint('Error parsing favorite_genres: $e');
        }
      }
    }
    
    // Parse appearance metadata if present
    Map<String, dynamic>? metadata;
    final metadataData = json['appearance_metadata'];
    if (metadataData != null) {
      if (metadataData is Map<String, dynamic>) {
        metadata = metadataData;
      } else if (metadataData is String) {
        try {
          metadata = jsonDecode(metadataData) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error parsing appearance_metadata: $e');
        }
      }
    }
    
    return Kid(
      id: json['id'] as String? ?? json['kid_id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String,
      age: json['age'] as int? ?? 5, // Default age if missing
      gender: json['gender'] as String?,
      avatarType: json['avatar_type'] as String? ?? 'profile1',
      appearanceMethod: json['appearance_method'] as String?,
      appearanceDescription: json['appearance_description'] as String?,
      appearanceExtractedAt: json['appearance_extracted_at'] != null 
          ? DateTime.tryParse(json['appearance_extracted_at'] as String) 
          : null,
      appearanceMetadata: metadata,
      favoriteGenres: genres,
      parentNotes: json['parent_notes'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'age': age,
      'gender': gender,
      'avatar_type': avatarType,
      'appearance_method': appearanceMethod,
      'appearance_description': appearanceDescription,
      'appearance_extracted_at': appearanceExtractedAt?.toIso8601String(),
      'appearance_metadata': appearanceMetadata,
      'favorite_genres': favoriteGenres,
      'parent_notes': parentNotes,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Kid copyWith({
    String? id,
    String? userId,
    String? name,
    int? age,
    String? gender,
    String? avatarType,
    String? appearanceMethod,
    String? appearanceDescription,
    DateTime? appearanceExtractedAt,
    Map<String, dynamic>? appearanceMetadata,
    List<String>? favoriteGenres,
    String? parentNotes,
    String? preferredLanguage,
    DateTime? createdAt,
  }) {
    return Kid(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      avatarType: avatarType ?? this.avatarType,
      appearanceMethod: appearanceMethod ?? this.appearanceMethod,
      appearanceDescription: appearanceDescription ?? this.appearanceDescription,
      appearanceExtractedAt: appearanceExtractedAt ?? this.appearanceExtractedAt,
      appearanceMetadata: appearanceMetadata ?? this.appearanceMetadata,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      parentNotes: parentNotes ?? this.parentNotes,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Kid && 
           other.id == id &&
           other.userId == userId &&
           other.name == name &&
           other.age == age &&
           other.gender == gender &&
           other.avatarType == avatarType &&
           other.appearanceMethod == appearanceMethod &&
           other.appearanceDescription == appearanceDescription &&
           other.appearanceExtractedAt == appearanceExtractedAt &&
           _mapEquals(other.appearanceMetadata, appearanceMetadata) &&
           _listEquals(other.favoriteGenres, favoriteGenres) &&
           other.parentNotes == parentNotes &&
           other.preferredLanguage == preferredLanguage;
  }
  
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
  
  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^ 
           userId.hashCode ^ 
           name.hashCode ^ 
           age.hashCode ^
           (gender?.hashCode ?? 0) ^
           avatarType.hashCode ^
           (appearanceMethod?.hashCode ?? 0) ^
           (appearanceDescription?.hashCode ?? 0) ^
           (appearanceExtractedAt?.hashCode ?? 0) ^
           (appearanceMetadata?.hashCode ?? 0) ^
           favoriteGenres.hashCode ^
           (parentNotes?.hashCode ?? 0) ^
           preferredLanguage.hashCode;
  }

  @override
  String toString() {
    return 'Kid(id: $id, name: $name, age: $age, gender: $gender, avatarType: $avatarType, appearanceMethod: $appearanceMethod, appearanceDescription: $appearanceDescription, favoriteGenres: $favoriteGenres, parentNotes: $parentNotes, preferredLanguage: $preferredLanguage)';
  }
}