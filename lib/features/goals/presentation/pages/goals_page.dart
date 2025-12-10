import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/supabase_helper.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/weekly_goal.dart';
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
  Timer? _timer;
  int _currentElapsedSeconds = 0;

  @override
  void dispose() {
    _targetMinutesController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(WeeklyGoal goal) {
    if (goal.status == GoalStatus.active && goal.startTime != null) {
      _currentElapsedSeconds = goal.elapsedMinutes * 60;
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _currentElapsedSeconds++;
          });
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final repository = GoalRepositoryImpl();
    return BlocProvider(
      create: (context) => GoalCubit(
        createWeeklyGoal: CreateWeeklyGoal(repository),
        getCurrentWeeklyGoal: GetCurrentWeeklyGoal(repository),
        calculateWeeklyProgress: CalculateWeeklyProgress(repository),
        goalRepository: repository,
      )..loadCurrentGoal(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Metas Semanales'),
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
        body: BlocListener<GoalCubit, GoalState>(
          listenWhen: (previous, current) {
            // Escuchar todos los cambios de estado para debugging
            print('🔄 Estado cambiado: ${previous.runtimeType} -> ${current.runtimeType}');
            return true;
          },
          listener: (context, state) {
            print('👂 BlocListener recibió estado: ${state.runtimeType}');
            
            if (state is GoalAchieved) {
              _showCelebrationAnimation(context);
            } else if (state is GoalError) {
              // Mostrar error siempre con más detalles
              print('🚨 Error en UI: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 8),
                  action: SnackBarAction(
                    label: 'Ver detalles',
                    textColor: Colors.white,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: SingleChildScrollView(
                            child: Text(state.message),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            } else if (state is GoalLoaded) {
              if (state.currentGoal != null) {
                print('✅ Meta cargada en UI: ${state.currentGoal!.id}');
                // Solo mostrar mensaje de éxito si acabamos de crear (no al cargar inicialmente)
                // Esto lo detectamos viendo si el estado anterior era GoalLoading
              }
            }
          },
          child: BlocBuilder<GoalCubit, GoalState>(
            builder: (context, state) {
              if (state is GoalLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is GoalError) {
                // Mostrar error pero permitir crear meta
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Error: ${state.message}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _buildGoalsView(context, null)),
                  ],
                );
              }

              if (state is GoalLoaded) {
                final goal = state.currentGoal;
                if (goal != null && goal.status == GoalStatus.active && goal.startTime != null) {
                  _startTimer(goal);
                } else {
                  _stopTimer();
                }
                
                return _buildGoalsView(context, goal);
              }

              if (state is GoalsListLoaded) {
                return _buildGoalsListView(context, state.goals);
              }

              // Estado inicial - mostrar formulario para crear meta
              return _buildGoalsView(context, null);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsView(BuildContext context, WeeklyGoal? currentGoal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentGoal != null) ...[
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _buildCurrentGoalCard(context, currentGoal),
            ),
            const SizedBox(height: 24),
          ],
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildCreateButton(context),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: _buildViewAllButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showCreateGoalDialog(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Crear Nueva Meta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        context.read<GoalCubit>().loadAllGoals(includeArchived: false);
      },
      icon: const Icon(Icons.list_alt),
      label: const Text('Ver Todas las Metas'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: BorderSide(color: Colors.blue.shade300, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCurrentGoalCard(BuildContext context, WeeklyGoal goal) {
    final totalElapsedSeconds = goal.status == GoalStatus.active && goal.startTime != null
        ? _currentElapsedSeconds
        : goal.elapsedMinutes * 60;
    
    final progress = goal.targetMinutes > 0
        ? (totalElapsedSeconds / 60.0 / goal.targetMinutes).clamp(0.0, 1.0)
        : 0.0;

    final statusColor = goal.status == GoalStatus.completed
        ? Colors.green
        : goal.status == GoalStatus.paused
            ? Colors.orange
            : Colors.blue;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            statusColor.shade50,
            statusColor.shade100.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        goal.status == GoalStatus.completed
                            ? Icons.check_circle
                            : goal.status == GoalStatus.paused
                                ? Icons.pause_circle
                                : Icons.play_circle,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Meta Actual',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'archive',
                      child: const Row(
                        children: [
                          Icon(Icons.archive, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('Archivar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    HapticFeedback.mediumImpact();
                    if (value == 'archive') {
                      context.read<GoalCubit>().archiveGoal(goal.id);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, goal.id);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Contador de tiempo animado
            Center(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Text(
                      _formatTime(totalElapsedSeconds),
                      key: ValueKey(totalElapsedSeconds),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: statusColor.shade700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Objetivo: ${goal.targetMinutes} minutos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Barra de progreso animada
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: progress),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Container(
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 16,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Botones de control con animaciones
            if (goal.status != GoalStatus.completed)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (goal.status == GoalStatus.active && goal.startTime != null)
                    _buildAnimatedButton(
                      context: context,
                      icon: Icons.pause,
                      label: 'Pausar',
                      color: Colors.orange,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.read<GoalCubit>().pauseGoal(goal.id);
                      },
                    )
                  else if (goal.status == GoalStatus.paused || goal.status == GoalStatus.active)
                    _buildAnimatedButton(
                      context: context,
                      icon: Icons.play_arrow,
                      label: 'Iniciar',
                      color: Colors.green,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.read<GoalCubit>().startGoal(goal.id);
                      },
                    ),
                  _buildAnimatedButton(
                    context: context,
                    icon: Icons.check_circle,
                    label: 'Finalizar',
                    color: Colors.blue,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.read<GoalCubit>().completeGoal(goal.id);
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // Badge de estado
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: goal.status == GoalStatus.completed
                    ? Container(
                        key: const ValueKey('completed'),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.celebration, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '¡Meta Completada!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : goal.status == GoalStatus.paused
                        ? Container(
                            key: const ValueKey('paused'),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade400,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pause_circle_outline, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Pausada',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsListView(BuildContext context, List<WeeklyGoal> goals) {
    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        final statusColor = goal.status == GoalStatus.completed
            ? Colors.green
            : goal.status == GoalStatus.paused
                ? Colors.orange
                : Colors.blue;
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  statusColor.shade50,
                  statusColor.shade100.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  goal.status == GoalStatus.completed
                                      ? Icons.flag
                                      : goal.status == GoalStatus.paused
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                  color: statusColor.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${goal.targetMinutes} minutos',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor.shade700,
                                    ),
                                  ),
                                  Text(
                                    _getStatusText(goal.status),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          PopupMenuButton(
                            icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              if (!goal.archived)
                                PopupMenuItem(
                                  value: 'archive',
                                  child: const Row(
                                    children: [
                                      Icon(Icons.archive, color: Colors.blue),
                                      SizedBox(width: 12),
                                      Text('Archivar'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              HapticFeedback.mediumImpact();
                              if (value == 'archive') {
                                context.read<GoalCubit>().archiveGoal(goal.id);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(context, goal.id);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            '${goal.elapsedMinutes} minutos registrados',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd/MM/yyyy').format(goal.createdAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return 'Activa';
      case GoalStatus.paused:
        return 'Pausada';
      case GoalStatus.completed:
        return 'Completada';
    }
  }

  void _showCreateGoalDialog(BuildContext context) {
    // Obtener el cubit antes de abrir el diálogo para asegurar que tenemos el contexto correcto
    final cubit = context.read<GoalCubit>();
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flag,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Crear Nueva Meta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Establece tu objetivo semanal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _targetMinutesController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Minutos objetivo',
                  hintText: 'Ej: 150',
                  prefixIcon: const Icon(Icons.timer_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _targetMinutesController.clear();
                      Navigator.pop(dialogContext);
                    },
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final minutes = int.tryParse(_targetMinutesController.text);
                          if (minutes == null || minutes <= 0) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: const Text('Por favor ingresa un número válido de minutos'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                          
                          print('🎯 Diálogo: Intentando crear meta con $minutes minutos');
                          
                          final now = DateTime.now();
                          final weekStart = now.subtract(Duration(days: now.weekday - 1));
                          
                          print('📅 Diálogo: weekStart = $weekStart');
                          print('👤 Diálogo: userId = ${SupabaseHelper.currentUser?.id}');
                          
                          _targetMinutesController.clear();
                          Navigator.pop(dialogContext);
                          
                          // Crear la meta después de cerrar el diálogo
                          print('🚀 Diálogo: Llamando a createGoal...');
                          try {
                            await cubit.createGoal(
                              weekStart: weekStart,
                              targetMinutes: minutes,
                            );
                            print('✅ Diálogo: createGoal completado');
                          } catch (e) {
                            print('❌ Diálogo: Excepción al crear meta: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Crear',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Meta'),
        content: const Text('¿Estás seguro de que quieres eliminar esta meta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GoalCubit>().deleteGoal(goalId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
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


