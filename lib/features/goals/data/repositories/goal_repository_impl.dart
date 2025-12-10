import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/supabase_helper.dart';
import '../../domain/entities/weekly_goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../models/weekly_goal_model.dart';

class GoalRepositoryImpl implements GoalRepository {
  @override
  Future<Either<Failure, WeeklyGoal>> createWeeklyGoal({
    required DateTime weekStart,
    required int targetMinutes,
  }) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      
      final progressResult = await calculateWeeklyProgress(weekStart: weekStartDate);
      final actualMinutes = progressResult.fold(
        (failure) => 0,
        (minutes) => minutes,
      );

      final goal = WeeklyGoalModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        weekStart: weekStartDate,
        targetMinutes: targetMinutes,
        achieved: actualMinutes >= targetMinutes,
        actualMinutes: actualMinutes,
        createdAt: DateTime.now(),
      );

      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .insert(goal.toJson())
          .select()
          .single();

      return Right(WeeklyGoalModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyGoal?>> getCurrentWeeklyGoal() async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .select()
          .eq('user_id', userId)
          .eq('week_start', weekStartDate.toIso8601String().split('T')[0])
          .maybeSingle();

      if (response == null) {
        return const Right(null);
      }

      return Right(WeeklyGoalModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WeeklyGoal>>> getWeeklyGoalsHistory() async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .select()
          .eq('user_id', userId)
          .order('week_start', ascending: false);

      final goals = (response as List)
          .map((json) => WeeklyGoalModel.fromJson(json))
          .toList();

      return Right(goals);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyGoal>> updateWeeklyGoal(WeeklyGoal goal) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final goalModel = WeeklyGoalModel(
        id: goal.id,
        userId: userId,
        weekStart: goal.weekStart,
        targetMinutes: goal.targetMinutes,
        achieved: goal.achieved,
        actualMinutes: goal.actualMinutes,
        createdAt: goal.createdAt,
      );

      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .update(goalModel.toJson())
          .eq('id', goal.id)
          .eq('user_id', userId)
          .select()
          .single();

      return Right(WeeklyGoalModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> calculateWeeklyProgress({
    required DateTime weekStart,
  }) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekEndDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

      final response = await SupabaseHelper.client.rpc(
        'calculate_weekly_progress',
        params: {
          'user_uuid': userId,
          'week_date': weekStart.toIso8601String().split('T')[0],
        },
      );

      return Right(response as int);
    } catch (e) {
      // Si la función RPC no existe, calcular manualmente
      try {
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekEndDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

        final response = await SupabaseHelper.client
            .from('activities')
            .select('duration_minutes')
            .eq('user_id', userId!)
            .gte('activity_date', weekStart.toIso8601String())
            .lte('activity_date', weekEndDate.toIso8601String());

        final totalMinutes = (response as List)
            .fold<int>(0, (sum, json) => sum + (json['duration_minutes'] as int));

        return Right(totalMinutes);
      } catch (e2) {
        return Left(ServerFailure(e2.toString()));
      }
    }
  }
}


