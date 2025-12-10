import '../../domain/entities/weekly_goal.dart';

class WeeklyGoalModel extends WeeklyGoal {
  const WeeklyGoalModel({
    required super.id,
    required super.userId,
    required super.weekStart,
    required super.targetMinutes,
    required super.achieved,
    required super.actualMinutes,
    super.status,
    super.elapsedMinutes,
    super.startTime,
    super.endTime,
    super.archived,
    super.deleted,
    required super.createdAt,
    super.updatedAt,
  });

  factory WeeklyGoalModel.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      targetMinutes: json['target_minutes'] as int,
      achieved: json['achieved'] as bool,
      actualMinutes: json['actual_minutes'] as int,
      status: _parseStatus(json['status'] as String?),
      elapsedMinutes: json['elapsed_minutes'] as int? ?? 0,
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      archived: json['archived'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static GoalStatus _parseStatus(String? status) {
    switch (status) {
      case 'paused':
        return GoalStatus.paused;
      case 'completed':
        return GoalStatus.completed;
      case 'active':
      default:
        return GoalStatus.active;
    }
  }

  static String _statusToString(GoalStatus status) {
    switch (status) {
      case GoalStatus.paused:
        return 'paused';
      case GoalStatus.completed:
        return 'completed';
      case GoalStatus.active:
        return 'active';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'week_start': weekStart.toIso8601String().split('T')[0],
      'target_minutes': targetMinutes,
      'achieved': achieved,
      'actual_minutes': actualMinutes,
      'status': _statusToString(status),
      'elapsed_minutes': elapsedMinutes,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'archived': archived,
      'deleted': deleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}


