import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> me();
  Future<UserModel> syncUser({String? fullName, String? phone, String? provider});

  /// Asks the backend (which uses Supabase Admin API) whether [email] is
  /// already registered. Sends ZERO emails. No auth token required.
  Future<bool> checkEmail(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserModel> me() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  @override
  Future<UserModel> syncUser({String? fullName, String? phone, String? provider}) async {
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (provider != null) 'provider': provider,
    };

    final res = await _dio.post(ApiEndpoints.syncUser, data: body);
    final data = res.data as Map<String, dynamic>;
    // Backend returns { success: true, user: { ...postgres row } }
    return UserModel.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  @override
  Future<bool> checkEmail(String email) async {
    final res = await _dio.get(
      ApiEndpoints.checkEmail,
      queryParameters: {'email': email},
    );
    final data = res.data as Map<String, dynamic>;
    return data['exists'] == true;
  }
}
