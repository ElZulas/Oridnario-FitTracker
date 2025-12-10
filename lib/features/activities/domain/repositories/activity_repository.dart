import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/activity.dart';

abstract class ActivityRepository {
  Future<Either<Failure, List<Activity>>> getActivities({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, Activity>> createActivity(Activity activity);

  Future<Either<Failure, Activity>> updateActivity(Activity activity);

  Future<Either<Failure, void>> deleteActivity(String activityId);

  Future<Either<Failure, List<DateTime>>> getActivityDates();

  Future<Either<Failure, Map<String, int>>> getActivitiesByType({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, List<int>>> getDailyMinutes({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, int>> getCurrentStreak();
}


