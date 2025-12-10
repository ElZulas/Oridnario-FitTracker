part of 'goal_cubit.dart';

abstract class GoalState extends Equatable {
  const GoalState();

  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalLoaded extends GoalState {
  final WeeklyGoal? currentGoal;

  const GoalLoaded(this.currentGoal);

  @override
  List<Object?> get props => [currentGoal];
}

class GoalAchieved extends GoalState {
  final WeeklyGoal goal;

  const GoalAchieved(this.goal);

  @override
  List<Object?> get props => [goal];
}

class GoalError extends GoalState {
  final String message;

  const GoalError(this.message);

  @override
  List<Object?> get props => [message];
}


