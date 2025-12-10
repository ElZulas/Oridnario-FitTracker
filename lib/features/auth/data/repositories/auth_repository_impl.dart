import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/supabase_helper.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const String _rememberMeKey = 'remember_me';
  static const String _userIdKey = 'user_id';

  @override
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseHelper.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left(AuthFailure('Error al crear la cuenta'));
      }

      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final response = await SupabaseHelper.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left(AuthFailure('Credenciales inválidas'));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);
      if (rememberMe) {
        await prefs.setString(_userIdKey, response.user!.id);
      }

      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await SupabaseHelper.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_userIdKey);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getCurrentUserProfile() async {
    try {
      final user = SupabaseHelper.currentUser;
      if (user == null) {
        return const Right(null);
      }

      final response = await SupabaseHelper.client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return const Right(null);
      }

      final profile = UserProfileModel.fromJson(response);
      return Right(profile);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final user = SupabaseHelper.currentUser;
      if (user != null) {
        return Right(true);
      }

      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (rememberMe) {
        final userId = prefs.getString(_userIdKey);
        if (userId != null) {
          final session = await SupabaseHelper.client.auth.getSession();
          return Right(session.session != null);
        }
      }

      return const Right(false);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      final user = SupabaseHelper.currentUser;
      if (user == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      await SupabaseHelper.client.auth.resend(
        type: 'signup',
        email: user.email!,
      );

      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}


