import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../cubit/auth_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      
      if (authState is AuthAuthenticated) {
        final profile = authState.profile;
        if (profile?.weightKg == null || profile?.heightCm == null) {
          context.go('/onboarding');
        } else {
          context.go('/dashboard');
        }
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación Lottie (necesitas agregar el archivo .json en assets/animations/)
            Lottie.asset(
              'assets/animations/fitness.json',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.fitness_center,
                  size: 100,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'FitTracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}


