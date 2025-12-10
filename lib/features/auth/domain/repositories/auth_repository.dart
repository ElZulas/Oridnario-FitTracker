import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserProfile?>> getCurrentUserProfile();

  Future<Either<Failure, bool>> isAuthenticated();

  Future<Either<Failure, void>> sendEmailVerification();
}


