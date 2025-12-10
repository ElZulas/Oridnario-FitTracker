import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/activity_repository.dart';

class GetCurrentStreak implements UseCaseNoParams<int> {
  final ActivityRepository repository;

  GetCurrentStreak(this.repository);

  @override
  Future<Either<Failure, int>> call() async {
    return await repository.getCurrentStreak();
  }
}


