import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/supabase_helper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedActivityLevel;

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveProfile() async {
    final userId = SupabaseHelper.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseHelper.client.from('user_profiles').upsert({
        'id': userId,
        'weight_kg': double.tryParse(_weightController.text),
        'height_cm': int.tryParse(_heightController.text),
        'age': int.tryParse(_ageController.text),
        'activity_level': _selectedActivityLevel,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar perfil: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de progreso
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Colors.blue
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Contenido de las páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
            // Botones de navegación
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Atrás'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == 2 ? 'Finalizar' : 'Siguiente'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/onboarding1.json',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.person, size: 100);
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Bienvenido a FitTracker',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Vamos a configurar tu perfil para comenzar',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/onboarding2.json',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.height, size: 100);
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Datos Personales',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              prefixIcon: Icon(Icons.monitor_weight),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altura (cm)',
              prefixIcon: Icon(Icons.height),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Edad',
              prefixIcon: Icon(Icons.cake),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/onboarding3.json',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.fitness_center, size: 100);
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Nivel de Actividad',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...AppConstants.activityLevels.map((level) {
            final labels = {
              'sedentary': 'Sedentario',
              'light': 'Ligero',
              'moderate': 'Moderado',
              'active': 'Activo',
            };
            return RadioListTile<String>(
              title: Text(labels[level] ?? level),
              value: level,
              groupValue: _selectedActivityLevel,
              onChanged: (value) {
                setState(() {
                  _selectedActivityLevel = value;
                });
              },
            );
          }),
        ],
      ),
    );
  }
}


