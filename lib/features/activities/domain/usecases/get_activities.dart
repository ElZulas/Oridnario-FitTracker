import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

class GetActivities implements UseCase<List<Activity>, GetActivitiesParams> {
  final ActivityRepository repository;

  GetActivities(this.repository);

  @override
  Future<Either<Failure, List<Activity>>> call(GetActivitiesParams params) async {
    return await repository.getActivities(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetActivitiesParams {
  final DateTime? startDate;
  final DateTime? endDate;

  GetActivitiesParams({this.startDate, this.endDate});
}


