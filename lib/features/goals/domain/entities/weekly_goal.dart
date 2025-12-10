import 'package:equatable/equatable.dart';

class WeeklyGoal extends Equatable {
  final String id;
  final String userId;
  final DateTime weekStart;
  final int targetMinutes;
  final bool achieved;
  final int actualMinutes;
  final DateTime createdAt;

  const WeeklyGoal({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.targetMinutes,
    required this.achieved,
    required this.actualMinutes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        weekStart,
        targetMinutes,
        achieved,
        actualMinutes,
        createdAt,
      ];
}


