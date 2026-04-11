import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.supabaseUid,
    required super.email,
    super.name,
    super.phone,
    super.avatar,
    super.authProvider,
    super.isActive,
    super.isBlocked,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      supabaseUid: json['supabase_uid'] as String? ?? '',
      email: json['email'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      authProvider: json['auth_provider'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isBlocked: json['is_blocked'] as bool? ?? false,
    );
  }
}

