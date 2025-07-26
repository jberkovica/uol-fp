/// Kid model representing a child profile linked to a user account
class Kid {
  final String id;
  final String userId;
  final String name;
  final int age;
  final String avatarType;
  final DateTime createdAt;

  const Kid({
    required this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.avatarType,
    required this.createdAt,
  });

  factory Kid.fromJson(Map<String, dynamic> json) {
    return Kid(
      id: json['id'] as String? ?? json['kid_id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String,
      age: json['age'] as int? ?? 5,
      avatarType: json['avatar_type'] as String? ?? 'hero1',
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  Kid copyWith({
    String? id,
    String? userId,
    String? name,
    int? age,
    String? avatarType,
    DateTime? createdAt,
  }) {
    return Kid(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarType: avatarType ?? this.avatarType,
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
           other.avatarType == avatarType;
  }

  @override
  int get hashCode {
    return id.hashCode ^ 
           userId.hashCode ^ 
           name.hashCode ^ 
           age.hashCode ^
           avatarType.hashCode;
  }

  @override
  String toString() {
    return 'Kid(id: $id, name: $name, age: $age, avatarType: $avatarType)';
  }
}