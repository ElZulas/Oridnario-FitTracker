import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../activities/data/repositories/activity_repository_impl.dart';
import '../../../activities/domain/usecases/get_activities.dart';
import '../../../activities/domain/usecases/create_activity.dart';
import '../../../activities/domain/usecases/update_activity.dart';
import '../../../activities/domain/usecases/delete_activity.dart';
import '../../../activities/domain/usecases/get_activities_by_type.dart';
import '../../../activities/domain/usecases/get_daily_minutes.dart';
import '../../../activities/domain/usecases/get_current_streak.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../../../goals/data/repositories/goal_repository_impl.dart';
import '../../../goals/domain/usecases/create_weekly_goal.dart';
import '../../../goals/domain/usecases/get_current_weekly_goal.dart';
import '../../../goals/domain/usecases/calculate_weekly_progress.dart';
import '../../../goals/presentation/cubit/goal_cubit.dart';
import '../../../weather/data/repositories/weather_repository_impl.dart';
import '../../../weather/data/datasources/weather_remote_datasource.dart';
import '../../../weather/domain/usecases/get_current_weather.dart';
import '../../../weather/presentation/cubit/weather_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late ActivityCubit _activityCubit;
  late GoalCubit _goalCubit;
  late WeatherCubit _weatherCubit;

  @override
  void initState() {
    super.initState();
    final activityRepo = ActivityRepositoryImpl();
    final goalRepo = GoalRepositoryImpl();
    final weatherRepo = WeatherRepositoryImpl(
      remoteDataSource: WeatherRemoteDataSourceImpl(dio: Dio()),
    );

    _activityCubit = ActivityCubit(
      getActivities: GetActivities(activityRepo),
      createActivity: CreateActivity(activityRepo),
      updateActivity: UpdateActivity(activityRepo),
      deleteActivity: DeleteActivity(activityRepo),
      getActivitiesByType: GetActivitiesByType(activityRepo),
      getDailyMinutes: GetDailyMinutes(activityRepo),
      getCurrentStreak: GetCurrentStreak(activityRepo),
    );

    _goalCubit = GoalCubit(
      createWeeklyGoal: CreateWeeklyGoal(goalRepo),
      getCurrentWeeklyGoal: GetCurrentWeeklyGoal(goalRepo),
      calculateWeeklyProgress: CalculateWeeklyProgress(goalRepo),
    );

    _weatherCubit = WeatherCubit(
      getCurrentWeather: GetCurrentWeather(weatherRepo),
    );

    _loadData();
  }

  void _loadData() {
    _activityCubit.loadActivities();
    _goalCubit.loadCurrentGoal();
    // Obtener ubicación del usuario (por ahora usar coordenadas por defecto)
    _weatherCubit.getWeather(latitude: 40.7128, longitude: -74.0060);
  }

  @override
  void dispose() {
    _activityCubit.close();
    _goalCubit.close();
    _weatherCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _activityCubit),
        BlocProvider.value(value: _goalCubit),
        BlocProvider.value(value: _weatherCubit),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FitTracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeatherCard(),
                const SizedBox(height: 16),
                _buildSummaryCards(),
                const SizedBox(height: 16),
                _buildWeeklyProgress(),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/activity/form'),
          icon: const Icon(Icons.add),
          label: const Text('Agregar Actividad'),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) {
        if (state is WeatherLoaded) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.weather.temperature.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(state.weather.description),
                        Text(
                          state.weather.activityRecommendation,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        if (state is ActivityLoaded) {
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));

          final weekActivities = state.activities.where((a) {
            return a.activityDate.isAfter(weekStart) &&
                a.activityDate.isBefore(weekEnd.add(const Duration(days: 1)));
          }).toList();

          final totalMinutes = weekActivities.fold<int>(
            0,
            (sum, activity) => sum + activity.durationMinutes,
          );

          final avgDaily = weekActivities.isNotEmpty
              ? totalMinutes / weekActivities.length
              : 0.0;

          return Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Minutos Semana',
                  totalMinutes.toString(),
                  Icons.timer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Promedio Diario',
                  avgDaily.toStringAsFixed(1),
                  Icons.trending_up,
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    return BlocBuilder<GoalCubit, GoalState>(
      builder: (context, state) {
        if (state is GoalLoaded && state.currentGoal != null) {
          final goal = state.currentGoal!;
          final progress = goal.targetMinutes > 0
              ? (goal.actualMinutes / goal.targetMinutes).clamp(0.0, 1.0)
              : 0.0;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meta Semanal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${goal.actualMinutes} / ${goal.targetMinutes} minutos',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Calendario',
                Icons.calendar_today,
                () => context.go('/activities/calendar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                'Metas',
                Icons.flag,
                () => context.go('/goals'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                'Estadísticas',
                Icons.bar_chart,
                () => context.go('/statistics'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

