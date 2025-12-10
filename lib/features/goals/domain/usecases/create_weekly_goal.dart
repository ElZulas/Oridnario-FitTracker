import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/weekly_goal.dart';
import '../repositories/goal_repository.dart';

class CreateWeeklyGoal implements UseCase<WeeklyGoal, CreateWeeklyGoalParams> {
  final GoalRepository repository;

  CreateWeeklyGoal(this.repository);

  @override
  Future<Either<Failure, WeeklyGoal>> call(CreateWeeklyGoalParams params) async {
    return await repository.createWeeklyGoal(
      weekStart: params.weekStart,
      targetMinutes: params.targetMinutes,
    );
  }
}

class CreateWeeklyGoalParams {
  final DateTime weekStart;
  final int targetMinutes;

  CreateWeeklyGoalParams({
    required this.weekStart,
    required this.targetMinutes,
  });
}


