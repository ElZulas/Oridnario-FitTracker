import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/weekly_goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/usecases/create_weekly_goal.dart';
import '../../domain/usecases/get_current_weekly_goal.dart';
import '../../domain/usecases/calculate_weekly_progress.dart';

part 'goal_state.dart';

class GoalCubit extends Cubit<GoalState> {
  final CreateWeeklyGoal createWeeklyGoal;
  final GetCurrentWeeklyGoal getCurrentWeeklyGoal;
  final CalculateWeeklyProgress calculateWeeklyProgress;
  final GoalRepository goalRepository;

  GoalCubit({
    required this.createWeeklyGoal,
    required this.getCurrentWeeklyGoal,
    required this.calculateWeeklyProgress,
    required this.goalRepository,
  }) : super(GoalInitial());

  Future<void> loadCurrentGoal() async {
    print('🔄 GoalCubit: Cargando meta actual...');
    emit(GoalLoading());
    final result = await getCurrentWeeklyGoal();

    result.fold(
      (failure) {
        print('❌ GoalCubit: Error al cargar meta: ${failure.message}');
        emit(GoalError(failure.message));
      },
      (goal) {
        if (goal != null) {
          print('✅ GoalCubit: Meta cargada: ${goal.id}');
        } else {
          print('⚠️ GoalCubit: No hay meta actual');
        }
        emit(GoalLoaded(goal));
        if (goal != null) {
          _checkGoalAchievement(goal);
        }
      },
    );
  }

  Future<void> createGoal({
    required DateTime weekStart,
    required int targetMinutes,
  }) async {
    print('🎯 GoalCubit: Creando meta - weekStart: $weekStart, targetMinutes: $targetMinutes');
    emit(GoalLoading());
    final result = await createWeeklyGoal(CreateWeeklyGoalParams(
      weekStart: weekStart,
      targetMinutes: targetMinutes,
    ));

    result.fold(
      (failure) {
        print('❌ GoalCubit: Error al crear meta: ${failure.message}');
        emit(GoalError(failure.message));
      },
      (goal) {
        print('✅ GoalCubit: Meta creada exitosamente: ${goal.id}');
        emit(GoalLoaded(goal));
        _checkGoalAchievement(goal);
        // Recargar después de crear para asegurar que se muestre correctamente
        Future.delayed(const Duration(milliseconds: 300), () {
          print('🔄 GoalCubit: Recargando meta actual...');
          loadCurrentGoal();
        });
      },
    );
  }

  Future<void> updateProgress() async {
    final state = this.state;
    if (state is GoalLoaded && state.currentGoal != null) {
      final goal = state.currentGoal!;
      final result = await calculateWeeklyProgress(CalculateWeeklyProgressParams(
        weekStart: goal.weekStart,
      ));

      result.fold(
        (failure) => emit(GoalError(failure.message)),
        (actualMinutes) {
          final updatedGoal = goal.copyWith(
            achieved: actualMinutes >= goal.targetMinutes,
            actualMinutes: actualMinutes,
            updatedAt: DateTime.now(),
          );
          emit(GoalLoaded(updatedGoal));
          _checkGoalAchievement(updatedGoal);
        },
      );
    }
  }

  Future<void> startGoal(String goalId) async {
    emit(GoalLoading());
    final result = await goalRepository.startGoal(goalId);
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) {
        emit(GoalLoaded(goal));
        _checkGoalAchievement(goal);
      },
    );
  }

  Future<void> pauseGoal(String goalId) async {
    emit(GoalLoading());
    final result = await goalRepository.pauseGoal(goalId);
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) => emit(GoalLoaded(goal)),
    );
  }

  Future<void> completeGoal(String goalId) async {
    emit(GoalLoading());
    final result = await goalRepository.completeGoal(goalId);
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) {
        emit(GoalLoaded(goal));
        _checkGoalAchievement(goal);
        // Recargar después de un momento para asegurar que se actualice correctamente
        Future.delayed(const Duration(milliseconds: 500), () {
          loadCurrentGoal();
        });
      },
    );
  }

  Future<void> archiveGoal(String goalId) async {
    // Guardar el estado actual antes de archivar
    final currentState = state;
    emit(GoalLoading());
    final result = await goalRepository.archiveGoal(goalId);
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (_) {
        // Si estábamos en la vista de lista, recargar la lista
        // Si estábamos en la vista individual, recargar la meta actual
        if (currentState is GoalsListLoaded) {
          loadAllGoals(includeArchived: false);
        } else {
          loadCurrentGoal(); // Recargar para mostrar la siguiente meta
        }
      },
    );
  }

  Future<void> deleteGoal(String goalId) async {
    print('🗑️ GoalCubit: Intentando eliminar meta: $goalId');
    
    // Guardar el estado actual antes de eliminar
    final currentState = state;
    emit(GoalLoading());
    
    print('📞 GoalCubit: Llamando a goalRepository.deleteGoal...');
    final result = await goalRepository.deleteGoal(goalId);
    
    result.fold(
      (failure) {
        print('❌ GoalCubit: Error al eliminar: ${failure.message}');
        emit(GoalError(failure.message));
      },
      (_) {
        print('✅ GoalCubit: Meta eliminada exitosamente, recargando...');
        // Si estábamos en la vista de lista, recargar la lista
        // Si estábamos en la vista individual, recargar la meta actual
        if (currentState is GoalsListLoaded) {
          print('📋 GoalCubit: Recargando lista de metas...');
          loadAllGoals(includeArchived: false);
        } else {
          print('🎯 GoalCubit: Recargando meta actual...');
          loadCurrentGoal(); // Recargar para mostrar la siguiente meta
        }
      },
    );
  }

  Future<void> loadAllGoals({bool includeArchived = false}) async {
    emit(GoalLoading());
    final result = await goalRepository.getAllGoals(includeArchived: includeArchived);
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goals) => emit(GoalsListLoaded(goals)),
    );
  }

  void _checkGoalAchievement(WeeklyGoal goal) {
    if (goal.achieved && goal.status == GoalStatus.completed) {
      // Meta cumplida - se emitirá un estado especial para la animación
      emit(GoalAchieved(goal));
    }
  }
}


