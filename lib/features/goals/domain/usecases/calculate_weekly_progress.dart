import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/goal_repository.dart';

class CalculateWeeklyProgress implements UseCase<int, CalculateWeeklyProgressParams> {
  final GoalRepository repository;

  CalculateWeeklyProgress(this.repository);

  @override
  Future<Either<Failure, int>> call(CalculateWeeklyProgressParams params) async {
    return await repository.calculateWeeklyProgress(
      weekStart: params.weekStart,
    );
  }
}

class CalculateWeeklyProgressParams {
  final DateTime weekStart;

  CalculateWeeklyProgressParams({required this.weekStart});
}


