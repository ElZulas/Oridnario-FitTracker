part of 'activity_cubit.dart';

abstract class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<Activity> activities;

  const ActivityLoaded(this.activities);

  @override
  List<Object?> get props => [activities];
}

class ActivitiesByTypeLoaded extends ActivityState {
  final Map<String, int> activitiesByType;

  const ActivitiesByTypeLoaded(this.activitiesByType);

  @override
  List<Object?> get props => [activitiesByType];
}

class DailyMinutesLoaded extends ActivityState {
  final List<int> dailyMinutes;

  const DailyMinutesLoaded(this.dailyMinutes);

  @override
  List<Object?> get props => [dailyMinutes];
}

class CurrentStreakLoaded extends ActivityState {
  final int streak;

  const CurrentStreakLoaded(this.streak);

  @override
  List<Object?> get props => [streak];
}

class ActivityError extends ActivityState {
  final String message;

  const ActivityError(this.message);

  @override
  List<Object?> get props => [message];
}


