import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Fetches user data from PostgreSQL via GET /api/me.
  /// The Supabase token is injected automatically by the Dio interceptor.
  Future<Either<Failure, User>> me();

  /// Upserts the user in PostgreSQL via POST /api/auth/sync-user.
  /// Used on first-time registration and Google sign-in.
  Future<Either<Failure, User>> syncUser({String? fullName, String? phone, String? provider});

  /// Checks if an email is already registered in Supabase via the backend
  /// Admin API. Sends ZERO emails, no rate-limit risk.
  Future<Either<Failure, bool>> checkEmail(String email);
}
