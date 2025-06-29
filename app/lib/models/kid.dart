/// Kid model representing a child profile linked to a user account
class Kid {
  final String id;
  final String userId;
  final String name;
  final String avatarType;
  final DateTime createdAt;

  const Kid({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarType,
    required this.createdAt,
  });

  factory Kid.fromJson(Map<String, dynamic> json) {
    return Kid(
      id: json['kid_id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String,
      avatarType: json['avatar_type'] as String? ?? 'hero1',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kid_id': id,
      'user_id': userId,
      'name': name,
      'avatar_type': avatarType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Kid copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatarType,
    DateTime? createdAt,
  }) {
    return Kid(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
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
           other.avatarType == avatarType;
  }

  @override
  int get hashCode {
    return id.hashCode ^ 
           userId.hashCode ^ 
           name.hashCode ^ 
           avatarType.hashCode;
  }

  @override
  String toString() {
    return 'Kid(id: $id, name: $name, avatarType: $avatarType)';
  }
}