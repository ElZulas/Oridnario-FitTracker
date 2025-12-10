import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    super.weightKg,
    super.heightCm,
    super.age,
    super.activityLevel,
    required super.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      weightKg: json['weight_kg'] != null
          ? (json['weight_kg'] as num).toDouble()
          : null,
      heightCm: json['height_cm'] as int?,
      age: json['age'] as int?,
      activityLevel: json['activity_level'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'age': age,
      'activity_level': activityLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? id,
    double? weightKg,
    int? heightCm,
    int? age,
    String? activityLevel,
    DateTime? createdAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


