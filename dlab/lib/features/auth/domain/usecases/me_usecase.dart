import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/user.dart';
import '../repository/auth_repository.dart';

class MeUseCase {
  MeUseCase(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, User>> call() {
    return _repo.me();
  }
}
