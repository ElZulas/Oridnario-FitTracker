import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/utils/supabase_helper.dart';
import '../../../activities/data/repositories/activity_repository_impl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = SupabaseHelper.currentUser?.id;
      if (userId == null) return;

      final response = await SupabaseHelper.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        _userProfile = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final repository = ActivityRepositoryImpl();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final result = await repository.getActivities(
        startDate: weekStart,
        endDate: weekEnd,
      );

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${failure.message}')),
          );
        },
        (activities) async {
          final List<List<dynamic>> csvData = [
            ['Tipo', 'Duración (min)', 'Distancia (km)', 'Calorías', 'Fecha', 'Notas'],
            ...activities.map((activity) => [
                  activity.activityType,
                  activity.durationMinutes,
                  activity.distanceKm ?? '',
                  activity.caloriesBurned,
                  activity.activityDate.toIso8601String(),
                  activity.notes ?? '',
                ]),
          ];

          final csvString = const ListToCsvConverter().convert(csvData);
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/activities_${DateTime.now().millisecondsSinceEpoch}.csv');
          await file.writeAsString(csvString);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CSV exportado a: ${file.path}')),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseHelper.client.auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            'Datos Personales',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_userProfile != null) ...[
                            _buildProfileRow('Peso', '${_userProfile!['weight_kg'] ?? 'N/A'} kg'),
                            _buildProfileRow('Altura', '${_userProfile!['height_cm'] ?? 'N/A'} cm'),
                            _buildProfileRow('Edad', '${_userProfile!['age'] ?? 'N/A'} años'),
                            _buildProfileRow('Nivel de Actividad', _userProfile!['activity_level'] ?? 'N/A'),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navegar a editar perfil
                            },
                            child: const Text('Editar Perfil'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Historial de Actividades'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navegar a historial
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Exportar Datos a CSV'),
                      subtitle: const Text('Última semana'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _exportToCSV,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}


