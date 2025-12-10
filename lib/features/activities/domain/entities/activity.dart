import 'package:equatable/equatable.dart';

class Activity extends Equatable {
  final String id;
  final String userId;
  final String activityType;
  final int durationMinutes;
  final double? distanceKm;
  final int caloriesBurned;
  final DateTime activityDate;
  final String? notes;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.durationMinutes,
    this.distanceKm,
    required this.caloriesBurned,
    required this.activityDate,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        activityType,
        durationMinutes,
        distanceKm,
        caloriesBurned,
        activityDate,
        notes,
        createdAt,
      ];
}


