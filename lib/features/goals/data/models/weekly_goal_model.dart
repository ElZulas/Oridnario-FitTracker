import '../../domain/entities/weekly_goal.dart';

class WeeklyGoalModel extends WeeklyGoal {
  const WeeklyGoalModel({
    required super.id,
    required super.userId,
    required super.weekStart,
    required super.targetMinutes,
    required super.achieved,
    required super.actualMinutes,
    required super.createdAt,
  });

  factory WeeklyGoalModel.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      targetMinutes: json['target_minutes'] as int,
      achieved: json['achieved'] as bool,
      actualMinutes: json['actual_minutes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'week_start': weekStart.toIso8601String(),
      'target_minutes': targetMinutes,
      'achieved': achieved,
      'actual_minutes': actualMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}


