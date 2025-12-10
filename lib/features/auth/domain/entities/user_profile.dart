import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final double? weightKg;
  final int? heightCm;
  final int? age;
  final String? activityLevel;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.weightKg,
    this.heightCm,
    this.age,
    this.activityLevel,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        weightKg,
        heightCm,
        age,
        activityLevel,
        createdAt,
      ];
}


