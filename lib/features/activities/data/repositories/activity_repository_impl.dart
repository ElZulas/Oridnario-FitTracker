import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/supabase_helper.dart';
import '../../domain/entities/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../models/activity_model.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  @override
  Future<Either<Failure, List<Activity>>> getActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      var query = SupabaseHelper.client
          .from('activities')
          .select()
          .eq('user_id', userId)
          .order('activity_date', ascending: false);

      if (startDate != null) {
        query = query.gte('activity_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('activity_date', endDate.toIso8601String());
      }

      final response = await query;
      final activities = (response as List)
          .map((json) => ActivityModel.fromJson(json))
          .toList();

      return Right(activities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Activity>> createActivity(Activity activity) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final activityModel = ActivityModel(
        id: activity.id,
        userId: userId,
        activityType: activity.activityType,
        durationMinutes: activity.durationMinutes,
        distanceKm: activity.distanceKm,
        caloriesBurned: activity.caloriesBurned,
        activityDate: activity.activityDate,
        notes: activity.notes,
        createdAt: activity.createdAt,
      );

      final response = await SupabaseHelper.client
          .from('activities')
          .insert(activityModel.toJson())
          .select()
          .single();

      return Right(ActivityModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Activity>> updateActivity(Activity activity) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final activityModel = ActivityModel(
        id: activity.id,
        userId: userId,
        activityType: activity.activityType,
        durationMinutes: activity.durationMinutes,
        distanceKm: activity.distanceKm,
        caloriesBurned: activity.caloriesBurned,
        activityDate: activity.activityDate,
        notes: activity.notes,
        createdAt: activity.createdAt,
      );

      final response = await SupabaseHelper.client
          .from('activities')
          .update(activityModel.toJson())
          .eq('id', activity.id)
          .eq('user_id', userId)
          .select()
          .single();

      return Right(ActivityModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteActivity(String activityId) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      await SupabaseHelper.client
          .from('activities')
          .delete()
          .eq('id', activityId)
          .eq('user_id', userId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DateTime>>> getActivityDates() async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final response = await SupabaseHelper.client
          .from('activities')
          .select('activity_date')
          .eq('user_id', userId);

      final dates = (response as List)
          .map((json) => DateTime.parse(json['activity_date'] as String))
          .toSet()
          .toList();

      dates.sort();
      return Right(dates);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getActivitiesByType({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await getActivities(
        startDate: startDate,
        endDate: endDate,
      );

      return result.fold(
        (failure) => Left(failure),
        (activities) {
          final Map<String, int> activitiesByType = {};
          for (var activity in activities) {
            activitiesByType[activity.activityType] =
                (activitiesByType[activity.activityType] ?? 0) +
                    activity.durationMinutes;
          }
          return Right(activitiesByType);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> getDailyMinutes({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await getActivities(
        startDate: startDate,
        endDate: endDate,
      );

      return result.fold(
        (failure) => Left(failure),
        (activities) {
          final Map<DateTime, int> dailyMinutes = {};
          for (var activity in activities) {
            final date = DateTime(
              activity.activityDate.year,
              activity.activityDate.month,
              activity.activityDate.day,
            );
            dailyMinutes[date] =
                (dailyMinutes[date] ?? 0) + activity.durationMinutes;
          }

          final List<int> minutesList = [];
          var currentDate = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final end = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          );

          while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
            minutesList.add(dailyMinutes[currentDate] ?? 0);
            currentDate = currentDate.add(const Duration(days: 1));
          }

          return Right(minutesList);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getCurrentStreak() async {
    try {
      final datesResult = await getActivityDates();
      return datesResult.fold(
        (failure) => Left(failure),
        (dates) {
          if (dates.isEmpty) return const Right(0);

          dates.sort((a, b) => b.compareTo(a));
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          int streak = 0;
          DateTime? expectedDate = todayDate;

          for (var date in dates) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (expectedDate != null &&
                dateOnly.isAtSameMomentAs(expectedDate)) {
              streak++;
              expectedDate = expectedDate.subtract(const Duration(days: 1));
            } else if (expectedDate != null &&
                dateOnly.isBefore(expectedDate)) {
              break;
            }
          }

          return Right(streak);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}


