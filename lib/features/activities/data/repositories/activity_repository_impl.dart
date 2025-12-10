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
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.filter('activity_date', 'gte', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.filter('activity_date', 'lte', endDate.toIso8601String());
      }

      final response = await query.order('activity_date', ascending: false);
      final allActivities = (response as List)
          .map((json) => ActivityModel.fromJson(json))
          .toList();

      // Filtrar manualmente las actividades eliminadas y archivadas
      final activities = allActivities.where((activity) {
        // Excluir si está eliminada
        if (activity.deleted == true) {
          print('⏭️ Actividad ${activity.id} excluida: deleted=true');
          return false;
        }
        // Excluir si está archivada
        if (activity.archived == true) {
          print('⏭️ Actividad ${activity.id} excluida: archived=true');
          return false;
        }
        return true;
      }).toList();
      
      print('📊 Actividades filtradas: ${activities.length} de ${allActivities.length}');

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

      // NO incluir el ID al crear - dejar que Supabase lo genere automáticamente como UUID
      final activityData = {
        'user_id': userId,
        'activity_type': activity.activityType,
        'duration_minutes': activity.durationMinutes,
        'distance_km': activity.distanceKm,
        'calories_burned': activity.caloriesBurned,
        'activity_date': activity.activityDate.toIso8601String(),
        'notes': activity.notes,
      };

      final response = await SupabaseHelper.client
          .from('activities')
          .insert(activityData)
          .select()
          .single();

      return Right(ActivityModel.fromJson(response));
    } catch (e) {
      // Log del error para debugging
      print('Error al crear actividad: $e');
      return Left(ServerFailure('Error al crear actividad: ${e.toString()}'));
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
        archived: activity.archived,
        deleted: activity.deleted,
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

      final now = DateTime.now();
      // Marcar como eliminado usando deleted: true
      final response = await SupabaseHelper.client
          .from('activities')
          .update({
            'deleted': true,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', activityId)
          .eq('user_id', userId)
          .eq('deleted', false) // Solo actualizar si no está ya eliminada
          .select();

      // Verificar que se actualizó al menos una fila
      if ((response as List).isEmpty) {
        print('⚠️ No se pudo eliminar la actividad. Puede que ya esté eliminada o no exista.');
        return const Left(ServerFailure('No se pudo eliminar la actividad. Puede que ya esté eliminada o no exista.'));
      }

      print('✅ Actividad eliminada correctamente: $activityId');
      return const Right(null);
    } catch (e) {
      print('❌ Error al eliminar actividad: $e');
      return Left(ServerFailure('Error al eliminar actividad: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Activity>> archiveActivity(String activityId) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final now = DateTime.now();
      final response = await SupabaseHelper.client
          .from('activities')
          .update({
            'archived': true,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', activityId)
          .eq('user_id', userId)
          .select()
          .single();

      return Right(ActivityModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> permanentDeleteActivity(String activityId) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final now = DateTime.now();
      final response = await SupabaseHelper.client
          .from('activities')
          .update({
            'deleted': true,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', activityId)
          .eq('user_id', userId)
          .eq('deleted', false) // Solo actualizar si no está ya eliminada
          .select();

      // Verificar que se actualizó al menos una fila
      if ((response as List).isEmpty) {
        return const Left(ServerFailure('No se pudo eliminar la actividad. Puede que ya esté eliminada o no exista.'));
      }

      print('✅ Actividad eliminada permanentemente: $activityId');
      return const Right(null);
    } catch (e) {
      print('❌ Error al eliminar permanentemente: $e');
      return Left(ServerFailure('Error al eliminar actividad: ${e.toString()}'));
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
          .select('activity_date, deleted, archived')
          .eq('user_id', userId);

      // Filtrar actividades eliminadas y archivadas
      final validActivities = (response as List).where((json) {
        final deleted = json['deleted'] as bool? ?? false;
        final archived = json['archived'] as bool? ?? false;
        return !deleted && !archived;
      }).toList();

      final dates = validActivities
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


