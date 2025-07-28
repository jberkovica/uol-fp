import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Kid model representing a child profile linked to a user account
class Kid {
  final String id;
  final String userId;
  final String name;
  final int? age;
  final String avatarType;
  final String? hairColor;
  final String? hairLength;
  final String? skinColor;
  final String? eyeColor;
  final String? gender;
  final List<String> favoriteGenres;
  final DateTime createdAt;

  const Kid({
    required this.id,
    required this.userId,
    required this.name,
    this.age,
    required this.avatarType,
    this.hairColor,
    this.hairLength,
    this.skinColor,
    this.eyeColor,
    this.gender,
    this.favoriteGenres = const [],
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
          // TODO: Replace with proper logging framework
          debugPrint('Error parsing favorite_genres: $e');
        }
      }
    }
    
    return Kid(
      id: json['id'] as String? ?? json['kid_id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String,
      age: json['age'] as int?,
      avatarType: json['avatar_type'] as String? ?? 'profile1',
      hairColor: json['hair_color'] as String?,
      hairLength: json['hair_length'] as String?,
      skinColor: json['skin_color'] as String?,
      eyeColor: json['eye_color'] as String?,
      gender: json['gender'] as String?,
      favoriteGenres: genres,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kid_id': id,
      'user_id': userId,
      'name': name,
      'age': age,
      'avatar_type': avatarType,
      'hair_color': hairColor,
      'hair_length': hairLength,
      'skin_color': skinColor,
      'eye_color': eyeColor,
      'gender': gender,
      'favorite_genres': favoriteGenres,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Kid copyWith({
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
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarType: avatarType ?? this.avatarType,
      hairColor: hairColor ?? this.hairColor,
      hairLength: hairLength ?? this.hairLength,
      skinColor: skinColor ?? this.skinColor,
      eyeColor: eyeColor ?? this.eyeColor,
      gender: gender ?? this.gender,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
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
           other.avatarType == avatarType &&
           other.hairColor == hairColor &&
           other.hairLength == hairLength &&
           other.skinColor == skinColor &&
           other.eyeColor == eyeColor &&
           other.gender == gender &&
           _listEquals(other.favoriteGenres, favoriteGenres);
  }
  
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^ 
           userId.hashCode ^ 
           name.hashCode ^ 
           (age?.hashCode ?? 0) ^
           avatarType.hashCode ^
           (hairColor?.hashCode ?? 0) ^
           (hairLength?.hashCode ?? 0) ^
           (skinColor?.hashCode ?? 0) ^
           (eyeColor?.hashCode ?? 0) ^
           (gender?.hashCode ?? 0) ^
           favoriteGenres.hashCode;
  }

  @override
  String toString() {
    return 'Kid(id: $id, name: $name, age: $age, avatarType: $avatarType, hairColor: $hairColor, hairLength: $hairLength, skinColor: $skinColor, eyeColor: $eyeColor, gender: $gender, favoriteGenres: $favoriteGenres)';
  }
}