import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: BlocProvider(
        create: (context) {
          final repository = ActivityRepositoryImpl();
          return ActivityCubit(
            getActivities: GetActivities(repository),
            createActivity: CreateActivity(repository),
            updateActivity: UpdateActivity(repository),
            deleteActivity: DeleteActivity(repository),
            getActivitiesByType: GetActivitiesByType(repository),
            getDailyMinutes: GetDailyMinutes(repository),
            getCurrentStreak: GetCurrentStreak(repository),
            activityRepository: repository,
          )..loadActivities();
        },
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
        final today = DateTime.now();
        final activityDay = DateTime(
          activity.activityDate.year,
          activity.activityDate.month,
          activity.activityDate.day,
        );
        final todayDay = DateTime(today.year, today.month, today.day);
        final canEdit = activityDay.isAtSameMomentAs(todayDay);
        
        return ListTile(
          leading: const Icon(Icons.fitness_center),
          title: Text(activity.activityType),
          subtitle: Text('${activity.durationMinutes} minutos - ${activity.caloriesBurned} cal'),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              if (canEdit)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Archivar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit' && canEdit) {
                context.go('/activity/form?id=${activity.id}');
              } else if (value == 'archive') {
                context.read<ActivityCubit>().archiveActivity(activity.id);
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, activity.id);
              }
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: const Text('¿Estás seguro de que deseas eliminar permanentemente esta actividad? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<ActivityCubit>().permanentDeleteActivity(activityId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actividad eliminada permanentemente')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar Permanentemente'),
          ),
        ],
      ),
    );
  }
}


