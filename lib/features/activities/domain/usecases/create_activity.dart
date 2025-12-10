import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

class CreateActivity implements UseCase<Activity, Activity> {
  final ActivityRepository repository;

  CreateActivity(this.repository);

  @override
  Future<Either<Failure, Activity>> call(Activity params) async {
    return await repository.createActivity(params);
  }
}


