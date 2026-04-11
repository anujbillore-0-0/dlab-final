import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_failure_mapper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Either<Failure, User>> me() async {
    try {
      final user = await _remote.me();
      return Right(user);
    } catch (e) {
      return Left(NetworkFailureMapper.fromDio(e));
    }
  }

  @override
  Future<Either<Failure, User>> syncUser({String? fullName, String? phone, String? provider}) async {
    try {
      final user = await _remote.syncUser(fullName: fullName, phone: phone, provider: provider);
      return Right(user);
    } catch (e) {
      return Left(NetworkFailureMapper.fromDio(e));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmail(String email) async {
    try {
      final exists = await _remote.checkEmail(email);
      return Right(exists);
    } catch (e) {
      return Left(NetworkFailureMapper.fromDio(e));
    }
  }
}
