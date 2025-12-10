import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/activity_repository.dart';

class GetActivitiesByType implements UseCase<Map<String, int>, GetActivitiesByTypeParams> {
  final ActivityRepository repository;

  GetActivitiesByType(this.repository);

  @override
  Future<Either<Failure, Map<String, int>>> call(GetActivitiesByTypeParams params) async {
    return await repository.getActivitiesByType(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetActivitiesByTypeParams {
  final DateTime startDate;
  final DateTime endDate;

  GetActivitiesByTypeParams({
    required this.startDate,
    required this.endDate,
  });
}


