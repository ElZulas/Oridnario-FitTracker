import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class GetCurrentUserProfile implements UseCaseNoParams<UserProfile?> {
  final AuthRepository repository;

  GetCurrentUserProfile(this.repository);

  @override
  Future<Either<Failure, UserProfile?>> call() async {
    return await repository.getCurrentUserProfile();
  }
}


