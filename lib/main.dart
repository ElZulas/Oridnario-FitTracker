import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/navigation/app_router.dart';
import 'core/utils/supabase_helper.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/get_current_user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase (las credenciales deben configurarse en app_constants.dart)
  await SupabaseHelper.initialize();
  
  runApp(const FitTrackerApp());
}

class FitTrackerApp extends StatelessWidget {
  const FitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(
            signUp: SignUp(AuthRepositoryImpl()),
            signIn: SignIn(AuthRepositoryImpl()),
            getCurrentUserProfile: GetCurrentUserProfile(AuthRepositoryImpl()),
          )..checkAuthStatus(),
        ),
      ],
      child: MaterialApp.router(
        title: 'FitTracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
