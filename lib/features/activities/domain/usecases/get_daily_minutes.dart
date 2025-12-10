import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/activity_repository.dart';

class GetDailyMinutes implements UseCase<List<int>, GetDailyMinutesParams> {
  final ActivityRepository repository;

  GetDailyMinutes(this.repository);

  @override
  Future<Either<Failure, List<int>>> call(GetDailyMinutesParams params) async {
    return await repository.getDailyMinutes(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetDailyMinutesParams {
  final DateTime startDate;
  final DateTime endDate;

  GetDailyMinutesParams({
    required this.startDate,
    required this.endDate,
  });
}


