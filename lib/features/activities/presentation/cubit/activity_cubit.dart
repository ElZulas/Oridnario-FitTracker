import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/create_activity.dart';
import '../../domain/usecases/update_activity.dart';
import '../../domain/usecases/delete_activity.dart';
import '../../domain/usecases/get_activities_by_type.dart';
import '../../domain/usecases/get_daily_minutes.dart';
import '../../domain/usecases/get_current_streak.dart';

part 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  final GetActivities getActivities;
  final CreateActivity createActivity;
  final UpdateActivity updateActivity;
  final DeleteActivity deleteActivity;
  final GetActivitiesByType getActivitiesByType;
  final GetDailyMinutes getDailyMinutes;
  final GetCurrentStreak getCurrentStreak;
  final ActivityRepository activityRepository;

  ActivityCubit({
    required this.getActivities,
    required this.createActivity,
    required this.updateActivity,
    required this.deleteActivity,
    required this.getActivitiesByType,
    required this.getDailyMinutes,
    required this.getCurrentStreak,
    required this.activityRepository,
  }) : super(ActivityInitial());

  Future<void> loadActivities({DateTime? startDate, DateTime? endDate}) async {
    emit(ActivityLoading());
    final result = await getActivities(GetActivitiesParams(
      startDate: startDate,
      endDate: endDate,
    ));

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (activities) => emit(ActivityLoaded(activities)),
    );
  }

  Future<void> addActivity(Activity activity) async {
    emit(ActivityLoading());
    final result = await createActivity(activity);

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (createdActivity) {
        if (state is ActivityLoaded) {
          final currentActivities = (state as ActivityLoaded).activities;
          emit(ActivityLoaded([createdActivity, ...currentActivities]));
        } else {
          emit(ActivityLoaded([createdActivity]));
        }
      },
    );
  }

  Future<void> editActivity(Activity activity) async {
    emit(ActivityLoading());
    final result = await updateActivity(activity);

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (updatedActivity) {
        if (state is ActivityLoaded) {
          final currentActivities = (state as ActivityLoaded).activities;
          final updatedList = currentActivities.map((a) {
            return a.id == updatedActivity.id ? updatedActivity : a;
          }).toList();
          emit(ActivityLoaded(updatedList));
        }
      },
    );
  }

  Future<void> removeActivity(String activityId) async {
    emit(ActivityLoading());
    final result = await deleteActivity(activityId);

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (_) {
        if (state is ActivityLoaded) {
          final currentActivities = (state as ActivityLoaded).activities;
          final updatedList =
              currentActivities.where((a) => a.id != activityId).toList();
          emit(ActivityLoaded(updatedList));
        }
      },
    );
  }

  Future<void> archiveActivity(String activityId) async {
    emit(ActivityLoading());
    final result = await activityRepository.archiveActivity(activityId);

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (_) {
        if (state is ActivityLoaded) {
          final currentActivities = (state as ActivityLoaded).activities;
          final updatedList =
              currentActivities.where((a) => a.id != activityId).toList();
          emit(ActivityLoaded(updatedList));
        }
      },
    );
  }

  Future<void> permanentDeleteActivity(String activityId) async {
    emit(ActivityLoading());
    final result = await activityRepository.permanentDeleteActivity(activityId);

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (_) {
        if (state is ActivityLoaded) {
          final currentActivities = (state as ActivityLoaded).activities;
          final updatedList =
              currentActivities.where((a) => a.id != activityId).toList();
          emit(ActivityLoaded(updatedList));
        }
      },
    );
  }

  Future<void> loadActivitiesByType({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await getActivitiesByType(GetActivitiesByTypeParams(
      startDate: startDate,
      endDate: endDate,
    ));

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (activitiesByType) => emit(ActivitiesByTypeLoaded(activitiesByType)),
    );
  }

  Future<void> loadDailyMinutes({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await getDailyMinutes(GetDailyMinutesParams(
      startDate: startDate,
      endDate: endDate,
    ));

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (minutes) => emit(DailyMinutesLoaded(minutes)),
    );
  }

  Future<void> loadCurrentStreak() async {
    final result = await getCurrentStreak();

    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (streak) => emit(CurrentStreakLoaded(streak)),
    );
  }
}


