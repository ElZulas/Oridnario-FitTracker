import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../activities/data/repositories/activity_repository_impl.dart';
import '../../../activities/domain/usecases/get_activities.dart';
import '../../../activities/domain/usecases/create_activity.dart';
import '../../../activities/domain/usecases/update_activity.dart';
import '../../../activities/domain/usecases/delete_activity.dart';
import '../../../activities/domain/usecases/get_activities_by_type.dart';
import '../../../activities/domain/usecases/get_daily_minutes.dart';
import '../../../activities/domain/usecases/get_current_streak.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
        )..loadActivitiesByType(
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
        )..loadDailyMinutes(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estadísticas'),
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
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Semanal'),
              Tab(text: 'Mensual'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWeeklyTab(),
            _buildMonthlyTab(),
            _buildHistoricalTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTab() {
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        if (state is ActivitiesByTypeLoaded) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Actividades por Tipo (Última Semana)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: state.activitiesByType.values.isEmpty
                          ? 100
                          : state.activitiesByType.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                      barTouchData: BarTouchData(
                        enabled: false,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 &&
                                  index < state.activitiesByType.keys.length) {
                                return Text(
                                  state.activitiesByType.keys.elementAt(index),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: state.activitiesByType.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.value.toDouble(),
                              color: Colors.blue,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildMonthlyTab() {
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        if (state is DailyMinutesLoaded) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Minutos de Ejercicio por Día (Último Mes)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(show: true),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: state.dailyMinutes.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildHistoricalTab() {
    return const Center(
      child: Text('Vista histórica - Próximamente'),
    );
  }
}


