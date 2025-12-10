import 'package:equatable/equatable.dart';

enum GoalStatus { active, paused, completed }

class WeeklyGoal extends Equatable {
  final String id;
  final String userId;
  final DateTime weekStart;
  final int targetMinutes;
  final bool achieved;
  final int actualMinutes;
  final GoalStatus status;
  final int elapsedMinutes;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool archived;
  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WeeklyGoal({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.targetMinutes,
    required this.achieved,
    required this.actualMinutes,
    this.status = GoalStatus.active,
    this.elapsedMinutes = 0,
    this.startTime,
    this.endTime,
    this.archived = false,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  WeeklyGoal copyWith({
    String? id,
    String? userId,
    DateTime? weekStart,
    int? targetMinutes,
    bool? achieved,
    int? actualMinutes,
    GoalStatus? status,
    int? elapsedMinutes,
    DateTime? startTime,
    DateTime? endTime,
    bool? archived,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStart: weekStart ?? this.weekStart,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      achieved: achieved ?? this.achieved,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      status: status ?? this.status,
      elapsedMinutes: elapsedMinutes ?? this.elapsedMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      archived: archived ?? this.archived,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        weekStart,
        targetMinutes,
        achieved,
        actualMinutes,
        status,
        elapsedMinutes,
        startTime,
        endTime,
        archived,
        deleted,
        createdAt,
        updatedAt,
      ];
}


