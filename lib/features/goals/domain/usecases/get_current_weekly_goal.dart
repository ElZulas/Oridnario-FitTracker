import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/weekly_goal.dart';
import '../repositories/goal_repository.dart';

class GetCurrentWeeklyGoal implements UseCaseNoParams<WeeklyGoal?> {
  final GoalRepository repository;

  GetCurrentWeeklyGoal(this.repository);

  @override
  Future<Either<Failure, WeeklyGoal?>> call() async {
    return await repository.getCurrentWeeklyGoal();
  }
}


