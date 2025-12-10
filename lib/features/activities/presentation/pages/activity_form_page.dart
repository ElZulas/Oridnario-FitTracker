import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/supabase_helper.dart';
import '../../domain/entities/activity.dart';
import '../cubit/activity_cubit.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/create_activity.dart';
import '../../domain/usecases/update_activity.dart';
import '../../domain/usecases/delete_activity.dart';
import '../../domain/usecases/get_activities_by_type.dart';
import '../../domain/usecases/get_daily_minutes.dart';
import '../../domain/usecases/get_current_streak.dart';

class ActivityFormPage extends StatefulWidget {
  final String? activityId;

  const ActivityFormPage({super.key, this.activityId});

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedActivityType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.activityId != null;
  }

  Future<void> _loadActivity(BuildContext context) async {
    if (widget.activityId == null) return;
    
    if (!mounted) return;
    if (!context.mounted) return;
    
    final cubit = context.read<ActivityCubit>();
    await cubit.loadActivities();
    
    // Esperar a que se carguen las actividades
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final state = cubit.state;
    if (state is ActivityLoaded) {
      try {
        final activity = state.activities.firstWhere(
          (a) => a.id == widget.activityId,
        );
        
        // Validar que solo se puede editar actividades del día actual
        final today = DateTime.now();
        final activityDay = DateTime(
          activity.activityDate.year,
          activity.activityDate.month,
          activity.activityDate.day,
        );
        final todayDay = DateTime(today.year, today.month, today.day);
        
        if (!activityDay.isAtSameMomentAs(todayDay)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solo puedes editar actividades del día actual'),
              ),
            );
            context.pop();
          }
          return;
        }
        
        if (mounted) {
          setState(() {
            _selectedActivityType = activity.activityType;
            _durationController.text = activity.durationMinutes.toString();
            _distanceController.text = activity.distanceKm?.toString() ?? '';
            _caloriesController.text = activity.caloriesBurned.toString();
            _notesController.text = activity.notes ?? '';
            _selectedDate = DateTime(
              activity.activityDate.year,
              activity.activityDate.month,
              activity.activityDate.day,
            );
            _selectedTime = TimeOfDay.fromDateTime(activity.activityDate);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar actividad: $e')),
          );
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveActivity(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No estás autenticado. Por favor inicia sesión.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final activityDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Validar que solo se puede editar actividades del día actual
      if (_isEditing) {
        final today = DateTime.now();
        final activityDay = DateTime(
          activityDate.year,
          activityDate.month,
          activityDate.day,
        );
        final todayDay = DateTime(today.year, today.month, today.day);
        
        if (!activityDay.isAtSameMomentAs(todayDay)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solo puedes editar actividades del día actual'),
            ),
          );
          return;
        }
      }

      // Para nuevas actividades, no necesitamos pasar ID (Supabase lo genera)
      // Para editar, necesitamos el ID de la actividad existente
      final activity = Activity(
        id: widget.activityId ?? '', // Se ignorará al crear nueva actividad
        userId: userId,
        activityType: _selectedActivityType!,
        durationMinutes: int.parse(_durationController.text),
        distanceKm: _distanceController.text.isNotEmpty
            ? double.tryParse(_distanceController.text)
            : null,
        caloriesBurned: int.parse(_caloriesController.text),
        activityDate: activityDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
      );

      setState(() {
        _isSaving = true;
      });
      
      final cubit = context.read<ActivityCubit>();
      if (_isEditing) {
        cubit.editActivity(activity);
      } else {
        cubit.addActivity(activity);
      }
      // NO cerrar aquí - el listener se encargará de cerrar cuando se guarde exitosamente
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
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
        );
      },
      child: Builder(
        builder: (context) {
          // Cargar actividad después de que el BlocProvider esté disponible
          if (_isEditing && widget.activityId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                _loadActivity(context);
              }
            });
          }
          
          return BlocListener<ActivityCubit, ActivityState>(
            listener: (context, state) {
              if (state is ActivityError) {
                if (_isSaving) {
                  _isSaving = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${state.message}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } else if (state is ActivityLoaded) {
                if (_isSaving) {
                  // Actividad guardada exitosamente
                  _isSaving = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isEditing ? 'Actividad actualizada exitosamente' : 'Actividad guardada exitosamente'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  // Esperar un momento antes de cerrar para que el usuario vea el mensaje
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      context.pop();
                    }
                  });
                }
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(_isEditing ? 'Editar Actividad' : 'Nueva Actividad'),
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
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedActivityType,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Actividad',
                            prefixIcon: const Icon(Icons.fitness_center),
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
                        items: AppConstants.activityTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedActivityType = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona un tipo de actividad';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Duración (minutos)',
                            prefixIcon: const Icon(Icons.timer),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa la duración';
                            }
                            final minutes = int.tryParse(value);
                            if (minutes == null ||
                                minutes < AppConstants.minDurationMinutes ||
                                minutes > AppConstants.maxDurationMinutes) {
                              return 'Duración debe estar entre ${AppConstants.minDurationMinutes} y ${AppConstants.maxDurationMinutes} minutos';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: TextFormField(
                          controller: _distanceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Distancia (km) - Opcional',
                            prefixIcon: const Icon(Icons.straighten),
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
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final distance = double.tryParse(value);
                              if (distance == null ||
                                  distance < AppConstants.minDistanceKm ||
                                  distance > AppConstants.maxDistanceKm) {
                                return 'Distancia debe estar entre ${AppConstants.minDistanceKm} y ${AppConstants.maxDistanceKm} km';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: TextFormField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Calorías Quemadas',
                            prefixIcon: const Icon(Icons.local_fire_department),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa las calorías quemadas';
                            }
                            final calories = int.tryParse(value);
                            if (calories == null || calories < 0) {
                              return 'Calorías debe ser un número positivo';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 700),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _selectDate();
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Fecha',
                              prefixIcon: const Icon(Icons.calendar_today),
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
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _selectTime();
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Hora',
                              prefixIcon: const Icon(Icons.access_time),
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
                            child: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 900),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Notas (Opcional)',
                            prefixIcon: const Icon(Icons.note),
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
                      ),
                      const SizedBox(height: 32),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.blue.shade600],
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
                                _saveActivity(context);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEditing ? Icons.update : Icons.save,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isEditing ? 'Actualizar' : 'Guardar',
                                      style: const TextStyle(
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


