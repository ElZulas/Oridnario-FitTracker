import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _isEditing = widget.activityId != null;
    if (_isEditing) {
      _loadActivity();
    }
  }

  void _loadActivity() {
    // Cargar actividad existente si está editando
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

  void _saveActivity() {
    if (_formKey.currentState!.validate()) {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) return;

      final activityDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final activity = Activity(
        id: widget.activityId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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

      final cubit = context.read<ActivityCubit>();
      if (_isEditing) {
        cubit.editActivity(activity);
      } else {
        cubit.addActivity(activity);
      }

      context.pop();
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
      create: (context) => ActivityCubit(
        getActivities: GetActivities(ActivityRepositoryImpl()),
        createActivity: CreateActivity(ActivityRepositoryImpl()),
        updateActivity: UpdateActivity(ActivityRepositoryImpl()),
        deleteActivity: DeleteActivity(ActivityRepositoryImpl()),
        getActivitiesByType: GetActivitiesByType(ActivityRepositoryImpl()),
        getDailyMinutes: GetDailyMinutes(ActivityRepositoryImpl()),
        getCurrentStreak: GetCurrentStreak(ActivityRepositoryImpl()),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Actividad' : 'Nueva Actividad'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedActivityType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Actividad',
                    prefixIcon: Icon(Icons.fitness_center),
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.activityTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duración (minutos)',
                    prefixIcon: Icon(Icons.timer),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Distancia (km) - Opcional',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calorías Quemadas',
                    prefixIcon: Icon(Icons.local_fire_department),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_selectedTime.format(context)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas (Opcional)',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveActivity,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


