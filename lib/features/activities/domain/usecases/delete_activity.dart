import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/activity_repository.dart';

class DeleteActivity implements UseCase<void, String> {
  final ActivityRepository repository;

  DeleteActivity(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteActivity(params);
  }
}


