import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/weekly_goal.dart';
import '../../domain/usecases/create_weekly_goal.dart';
import '../../domain/usecases/get_current_weekly_goal.dart';
import '../../domain/usecases/calculate_weekly_progress.dart';
import '../../../../core/usecases/usecase.dart';

part 'goal_state.dart';

class GoalCubit extends Cubit<GoalState> {
  final CreateWeeklyGoal createWeeklyGoal;
  final GetCurrentWeeklyGoal getCurrentWeeklyGoal;
  final CalculateWeeklyProgress calculateWeeklyProgress;

  GoalCubit({
    required this.createWeeklyGoal,
    required this.getCurrentWeeklyGoal,
    required this.calculateWeeklyProgress,
  }) : super(GoalInitial());

  Future<void> loadCurrentGoal() async {
    emit(GoalLoading());
    final result = await getCurrentWeeklyGoal(NoParams());

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) {
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
    emit(GoalLoading());
    final result = await createWeeklyGoal(CreateWeeklyGoalParams(
      weekStart: weekStart,
      targetMinutes: targetMinutes,
    ));

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) {
        emit(GoalLoaded(goal));
        _checkGoalAchievement(goal);
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
          final updatedGoal = WeeklyGoal(
            id: goal.id,
            userId: goal.userId,
            weekStart: goal.weekStart,
            targetMinutes: goal.targetMinutes,
            achieved: actualMinutes >= goal.targetMinutes,
            actualMinutes: actualMinutes,
            createdAt: goal.createdAt,
          );
          emit(GoalLoaded(updatedGoal));
          _checkGoalAchievement(updatedGoal);
        },
      );
    }
  }

  void _checkGoalAchievement(WeeklyGoal goal) {
    if (goal.achieved && !goal.achieved) {
      // Meta cumplida - se emitirá un estado especial para la animación
      emit(GoalAchieved(goal));
    }
  }
}


