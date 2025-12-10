import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/get_current_user_profile.dart';
import '../../../../core/usecases/usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignUp signUp;
  final SignIn signIn;
  final GetCurrentUserProfile getCurrentUserProfile;

  AuthCubit({
    required this.signUp,
    required this.signIn,
    required this.getCurrentUserProfile,
  }) : super(AuthInitial());

  Future<void> signUpUser({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    final result = await signUp(SignUpParams(
      email: email,
      password: password,
    ));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthSuccess()),
    );
  }

  Future<void> signInUser({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    emit(AuthLoading());
    final result = await signIn(SignInParams(
      email: email,
      password: password,
      rememberMe: rememberMe,
    ));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) async {
        final profileResult = await getCurrentUserProfile(NoParams());
        profileResult.fold(
          (failure) => emit(AuthError(failure.message)),
          (profile) => emit(AuthAuthenticated(profile)),
        );
      },
    );
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    final result = await getCurrentUserProfile(NoParams());
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (profile) {
        if (profile != null) {
          emit(AuthAuthenticated(profile));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }
}


