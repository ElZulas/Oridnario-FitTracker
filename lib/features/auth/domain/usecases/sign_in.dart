import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/auth_repository.dart';

class SignIn implements UseCase<void, SignInParams> {
  final AuthRepository repository;

  SignIn(this.repository);

  @override
  Future<Either<Failure, void>> call(SignInParams params) async {
    return await repository.signIn(
      email: params.email,
      password: params.password,
      rememberMe: params.rememberMe,
    );
  }
}

class SignInParams {
  final String email;
  final String password;
  final bool rememberMe;

  SignInParams({
    required this.email,
    required this.password,
    required this.rememberMe,
  });
}


