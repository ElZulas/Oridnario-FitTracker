import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/create_activity.dart';
import '../../domain/usecases/update_activity.dart';
import '../../domain/usecases/delete_activity.dart';
import '../../domain/usecases/get_activities_by_type.dart';
import '../../domain/usecases/get_daily_minutes.dart';
import '../../domain/usecases/get_current_streak.dart';
import '../cubit/activity_cubit.dart';

class ActivitiesCalendarPage extends StatefulWidget {
  const ActivitiesCalendarPage({super.key});

  @override
  State<ActivitiesCalendarPage> createState() => _ActivitiesCalendarPageState();
}

class _ActivitiesCalendarPageState extends State<ActivitiesCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Set<DateTime> _activityDates = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Actividades'),
      ),
      body: BlocProvider(
        create: (context) => ActivityCubit(
          getActivities: GetActivities(ActivityRepositoryImpl()),
          createActivity: CreateActivity(ActivityRepositoryImpl()),
          updateActivity: UpdateActivity(ActivityRepositoryImpl()),
          deleteActivity: DeleteActivity(ActivityRepositoryImpl()),
          getActivitiesByType: GetActivitiesByType(ActivityRepositoryImpl()),
          getDailyMinutes: GetDailyMinutes(ActivityRepositoryImpl()),
          getCurrentStreak: GetCurrentStreak(ActivityRepositoryImpl()),
        )..loadActivities(),
        child: BlocBuilder<ActivityCubit, ActivityState>(
          builder: (context, state) {
            if (state is ActivityLoaded) {
              _activityDates = state.activities
                  .map((a) => DateTime(
                        a.activityDate.year,
                        a.activityDate.month,
                        a.activityDate.day,
                      ))
                  .toSet();
            }

            return Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.now(),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  eventLoader: (day) {
                    return _activityDates.contains(DateTime(
                      day.year,
                      day.month,
                      day.day,
                    ))
                        ? [1]
                        : [];
                  },
                  calendarStyle: const CalendarStyle(
                    markersMaxCount: 1,
                    markerDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                if (state is ActivityLoaded)
                  Expanded(
                    child: _buildActivitiesList(state.activities),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivitiesList(List<dynamic> activities) {
    final dayActivities = activities.where((a) {
      final activityDate = DateTime(
        a.activityDate.year,
        a.activityDate.month,
        a.activityDate.day,
      );
      return isSameDay(activityDate, _selectedDay);
    }).toList();

    if (dayActivities.isEmpty) {
      return const Center(
        child: Text('No hay actividades para este día'),
      );
    }

    return ListView.builder(
      itemCount: dayActivities.length,
      itemBuilder: (context, index) {
        final activity = dayActivities[index];
        return ListTile(
          leading: const Icon(Icons.fitness_center),
          title: Text(activity.activityType),
          subtitle: Text('${activity.durationMinutes} minutos'),
          trailing: Text('${activity.caloriesBurned} cal'),
        );
      },
    );
  }
}


