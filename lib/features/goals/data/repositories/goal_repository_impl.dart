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
    // Variables que se necesitan en el catch también
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

    // Primero intentar con solo los campos básicos que sabemos que existen
    final basicGoalData = {
      'user_id': userId,
      'week_start': weekStartDate.toIso8601String().split('T')[0],
      'target_minutes': targetMinutes,
      'achieved': actualMinutes >= targetMinutes,
      'actual_minutes': actualMinutes,
    };

    print('💾 Intentando guardar meta con datos básicos: $basicGoalData');
    
    try {
      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .insert(basicGoalData)
          .select()
          .single();

      print('✅ Meta guardada exitosamente en BD: ${response['id']}');
      print('📄 Respuesta completa: $response');
      
      final goal = WeeklyGoalModel.fromJson(response);
      print('✅ Meta parseada después de guardar: id=${goal.id}');
      
      return Right(goal);
    } catch (e) {
      print('❌ Error al guardar meta: $e');
      print('📊 Tipo de error: ${e.runtimeType}');
      print('📝 Stack trace: ${StackTrace.current}');
      
      // Si el error menciona columnas, puede ser que estemos intentando insertar algo incorrecto
      // O puede ser un error de permisos RLS
      final errorMessage = e.toString();
      if (errorMessage.contains('permission') || errorMessage.contains('policy') || errorMessage.contains('RLS')) {
        return Left(ServerFailure('Error de permisos: Verifica las políticas RLS en Supabase. $errorMessage'));
      }
      
      return Left(ServerFailure('Error al crear meta: $errorMessage'));
    }
  }

  @override
  Future<Either<Failure, WeeklyGoal?>> getCurrentWeeklyGoal() async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      print('🔍 Buscando metas para usuario: $userId');
      
      // Obtener la meta más reciente sin filtros complicados
      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      print('📦 Respuesta de Supabase: ${response.length} metas encontradas');
      
      if ((response as List).isEmpty) {
        print('⚠️ No se encontraron metas');
        return const Right(null);
      }

      // Filtrar manualmente para encontrar la primera que no esté archivada ni eliminada
      for (var json in response as List) {
        try {
          print('📝 Intentando parsear meta: ${json['id']}');
          final goal = WeeklyGoalModel.fromJson(json);
          print('✅ Meta parseada: id=${goal.id}, archived=${goal.archived}, deleted=${goal.deleted}');
          
          // Excluir solo si están explícitamente archivadas o eliminadas
          if (!goal.deleted && !goal.archived) {
            print('✅ Meta válida encontrada: ${goal.id}');
            return Right(goal);
          } else {
            print('⏭️ Meta archivada/eliminada, buscando siguiente...');
          }
        } catch (e) {
          print('❌ Error al parsear meta: $e');
          print('📄 JSON: $json');
          // Continuar con la siguiente meta
          continue;
        }
      }

      // Si todas están archivadas/eliminadas, retornar null
      print('⚠️ Todas las metas están archivadas o eliminadas');
      return const Right(null);
    } catch (e) {
      // Log del error para debugging
      print('❌ Error al obtener meta actual: $e');
      print('📊 Tipo de error: ${e.runtimeType}');
      // Si no hay metas, retornar null en lugar de error
      if (e.toString().contains('null') || e.toString().contains('No rows')) {
        return const Right(null);
      }
      return Left(ServerFailure('Error al cargar meta: ${e.toString()}'));
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
        status: goal.status,
        elapsedMinutes: goal.elapsedMinutes,
        startTime: goal.startTime,
        endTime: goal.endTime,
        archived: goal.archived,
        deleted: goal.deleted,
        createdAt: goal.createdAt,
        updatedAt: DateTime.now(),
      );

      final updateData = goalModel.toJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .update(updateData)
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
  Future<Either<Failure, List<WeeklyGoal>>> getAllGoals({
    bool includeArchived = false,
  }) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      // Intentar con filtros nuevos primero (si existen las columnas)
      dynamic response;
      try {
        var query = SupabaseHelper.client
            .from('weekly_goals')
            .select()
            .eq('user_id', userId);
        
        // Intentar filtrar por deleted y archived si existen
        try {
          query = query.eq('deleted', false);
          if (!includeArchived) {
            query = query.eq('archived', false);
          }
        } catch (_) {
          // Si las columnas no existen, continuar sin filtros
        }
        
        response = await query.order('created_at', ascending: false);
      } catch (e) {
        // Si falla, intentar sin filtros
        print('Error con filtros en getAllGoals, intentando sin filtros: $e');
        response = await SupabaseHelper.client
            .from('weekly_goals')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      }

      final goalsList = (response as List)
          .map((json) => WeeklyGoalModel.fromJson(json))
          .toList();

      // Filtrar manualmente si las columnas existen pero el filtro no funcionó
      final filteredGoals = goalsList.where((goal) {
        if (goal.deleted == true) return false;
        if (!includeArchived && goal.archived == true) return false;
        return true;
      }).toList();

      return Right(filteredGoals);
    } catch (e) {
      print('Error al obtener todas las metas: $e');
      return Left(ServerFailure('Error al cargar metas: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WeeklyGoal>> startGoal(String goalId) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final now = DateTime.now();
      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .update({
            'status': 'active',
            'start_time': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', goalId)
          .eq('user_id', userId)
          .select()
          .single();

      return Right(WeeklyGoalModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyGoal>> pauseGoal(String goalId) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      // Obtener la meta actual para calcular elapsed_minutes
      final currentGoal = await SupabaseHelper.client
          .from('weekly_goals')
          .select()
          .eq('id', goalId)
          .eq('user_id', userId)
          .single();

      final startTime = currentGoal['start_time'] != null
          ? DateTime.parse(currentGoal['start_time'] as String)
          : null;
      
      int elapsedMinutes = currentGoal['elapsed_minutes'] as int? ?? 0;
      if (startTime != null) {
        final now = DateTime.now();
        final additionalMinutes = now.difference(startTime).inMinutes;
        elapsedMinutes += additionalMinutes;
      }

      final now = DateTime.now();
      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .update({
            'status': 'paused',
            'elapsed_minutes': elapsedMinutes,
            'start_time': null,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', goalId)
          .eq('user_id', userId)
          .select()
          .single();

      return Right(WeeklyGoalModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyGoal>> completeGoal(String goalId) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      // Obtener la meta actual
      final currentGoal = await SupabaseHelper.client
          .from('weekly_goals')
          .select()
          .eq('id', goalId)
          .eq('user_id', userId)
          .single();

      final startTime = currentGoal['start_time'] != null
          ? DateTime.parse(currentGoal['start_time'] as String)
          : null;
      
      int elapsedMinutes = currentGoal['elapsed_minutes'] as int? ?? 0;
      if (startTime != null) {
        final now = DateTime.now();
        final additionalMinutes = now.difference(startTime).inMinutes;
        elapsedMinutes += additionalMinutes;
      }

      final now = DateTime.now();
      final response = await SupabaseHelper.client
          .from('weekly_goals')
          .update({
            'status': 'completed',
            'elapsed_minutes': elapsedMinutes,
            'end_time': now.toIso8601String(),
            'achieved': true,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', goalId)
          .eq('user_id', userId)
          .select()
          .single();

      return Right(WeeklyGoalModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyGoal>> archiveGoal(String goalId) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final now = DateTime.now();
      
      // Intentar actualizar con campo archived (si existe)
      dynamic response;
      try {
        response = await SupabaseHelper.client
            .from('weekly_goals')
            .update({
              'archived': true,
              'updated_at': now.toIso8601String(),
            })
            .eq('id', goalId)
            .eq('user_id', userId)
            .select()
            .single();
      } catch (e) {
        // Si la columna archived no existe, solo actualizar updated_at
        print('Error al archivar (columna puede no existir): $e');
        response = await SupabaseHelper.client
            .from('weekly_goals')
            .update({
              'updated_at': now.toIso8601String(),
            })
            .eq('id', goalId)
            .eq('user_id', userId)
            .select()
            .single();
      }

      return Right(WeeklyGoalModel.fromJson(response));
    } catch (e) {
      print('Error al archivar meta: $e');
      return Left(ServerFailure('Error al archivar meta: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String goalId) async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final now = DateTime.now();
      await SupabaseHelper.client
          .from('weekly_goals')
          .update({
            'deleted': true,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', goalId)
          .eq('user_id', userId);

      return const Right(null);
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
        final userId = SupabaseHelper.currentUser?.id;
        if (userId == null) {
          return const Left(AuthFailure('Usuario no autenticado'));
        }
        
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekEndDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

        final response = await SupabaseHelper.client
            .from('activities')
            .select('duration_minutes')
            .eq('user_id', userId)
            .filter('activity_date', 'gte', weekStart.toIso8601String())
            .filter('activity_date', 'lte', weekEndDate.toIso8601String());

        final totalMinutes = (response as List)
            .fold<int>(0, (sum, json) => sum + (json['duration_minutes'] as int));

        return Right(totalMinutes);
      } catch (e2) {
        return Left(ServerFailure(e2.toString()));
      }
    }
  }
}


