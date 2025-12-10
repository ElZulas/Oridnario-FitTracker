import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/weekly_goal.dart';

abstract class GoalRepository {
  Future<Either<Failure, WeeklyGoal>> createWeeklyGoal({
    required DateTime weekStart,
    required int targetMinutes,
  });

  Future<Either<Failure, WeeklyGoal?>> getCurrentWeeklyGoal();

  Future<Either<Failure, List<WeeklyGoal>>> getWeeklyGoalsHistory();

  Future<Either<Failure, WeeklyGoal>> updateWeeklyGoal(WeeklyGoal goal);

  Future<Either<Failure, int>> calculateWeeklyProgress({
    required DateTime weekStart,
  });
}


