import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.supabaseUid,
    required this.email,
    this.name,
    this.phone,
    this.avatar,
    this.authProvider,
    this.isActive = true,
    this.isBlocked = false,
  });

  final String id;           // PostgreSQL UUID
  final String supabaseUid;  // Supabase auth.users uid
  final String email;
  final String? name;
  final String? phone;
  final String? avatar;
  final String? authProvider; // 'email' | 'google'
  final bool isActive;
  final bool isBlocked;

  @override
  List<Object?> get props => [id, supabaseUid, email, name, phone, avatar, authProvider, isActive, isBlocked];
}

