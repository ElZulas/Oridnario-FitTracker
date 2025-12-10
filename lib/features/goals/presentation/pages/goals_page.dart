import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/usecases/create_weekly_goal.dart';
import '../../domain/usecases/get_current_weekly_goal.dart';
import '../../domain/usecases/calculate_weekly_progress.dart';
import '../cubit/goal_cubit.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final _targetMinutesController = TextEditingController();

  @override
  void dispose() {
    _targetMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GoalCubit(
        createWeeklyGoal: CreateWeeklyGoal(GoalRepositoryImpl()),
        getCurrentWeeklyGoal: GetCurrentWeeklyGoal(GoalRepositoryImpl()),
        calculateWeeklyProgress: CalculateWeeklyProgress(GoalRepositoryImpl()),
      )..loadCurrentGoal(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Metas Semanales'),
        ),
        body: BlocListener<GoalCubit, GoalState>(
          listener: (context, state) {
            if (state is GoalAchieved) {
              _showCelebrationAnimation(context);
            }
          },
          child: BlocBuilder<GoalCubit, GoalState>(
            builder: (context, state) {
              if (state is GoalLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is GoalLoaded) {
                final goal = state.currentGoal;
                if (goal == null) {
                  return _buildCreateGoalForm(context);
                }

                return _buildGoalProgress(context, goal);
              }

              return const Center(child: Text('Error al cargar metas'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCreateGoalForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Crea tu primera meta semanal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _targetMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutos objetivo por semana',
              prefixIcon: Icon(Icons.flag),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(_targetMinutesController.text);
              if (minutes != null && minutes > 0) {
                final now = DateTime.now();
                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                context.read<GoalCubit>().createGoal(
                      weekStart: weekStart,
                      targetMinutes: minutes,
                    );
              }
            },
            child: const Text('Crear Meta'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress(BuildContext context, dynamic goal) {
    final progress = goal.targetMinutes > 0
        ? (goal.actualMinutes / goal.targetMinutes).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meta Semanal Actual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 20,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${goal.actualMinutes} minutos',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        '/ ${goal.targetMinutes} minutos',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (goal.achieved)
                    const Chip(
                      label: Text('¡Meta Cumplida!'),
                      backgroundColor: Colors.green,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<GoalCubit>().updateProgress();
            },
            child: const Text('Actualizar Progreso'),
          ),
        ],
      ),
    );
  }

  void _showCelebrationAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/celebration.json',
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.celebration, size: 100);
                },
              ),
              const Text(
                '¡Felicidades!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('Has cumplido tu meta semanal'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


