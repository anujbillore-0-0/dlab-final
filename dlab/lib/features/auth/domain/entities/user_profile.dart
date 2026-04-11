class UserProfile {
  const UserProfile({
    required this.id,
    this.displayName,
    this.phone,
    this.birthday,
    this.gender,
    this.avatarUrl,
    this.receivesOffers = false,
  });

  final String id;
  final String? displayName;
  final String? phone;
  final String? birthday;   // stored as ISO date string e.g. "2000-01-25"
  final String? gender;
  final String? avatarUrl;
  final bool receivesOffers;

  /// Profile is considered complete once the user has set a display name.
  bool get isComplete => displayName != null && displayName!.trim().isNotEmpty;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        phone: json['phone'] as String?,
        birthday: json['birthday'] as String?,
        gender: json['gender'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        receivesOffers: json['receives_offers'] as bool? ?? false,
      );
}
