import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/provider/auth_providers.dart';
import '../../../auth/presentation/screens/register_screen.dart';
import '../../../notifications/presentation/screens/notifications_page.dart';
import '../../../wishlist/presentation/screens/wishlist_page.dart';
import 'contact_us_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'language_region_screen.dart';
import 'my_orders_screen.dart';
import 'order_return_screen.dart';
import 'saved_addresses_empty_screen.dart';
import 'terms_conditions_screen.dart';

const _primaryColor = Color(0xFF1B4965);
const _secondaryColor = Color(0xFF62B6CB);
const _backgroundColor = Color(0xFFFFFFFF);
const _mutedTextColor = Color(0xFF6B7280);
const _primaryFontColor = Color(0xFF111827);

final profileRepositoryProvider = Provider<_ProfileRepository>((ref) {
  return _ProfileRepository();
});

class _ProfileRepository {
  _ProfileRepository();

  Future<_LocalProfileCache> getLocalProfileDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return _LocalProfileCache(
      displayName: prefs.getString(profileLocalDisplayNameKey),
      phone: prefs.getString(profileLocalPhoneKey),
      birthday: prefs.getString(profileLocalBirthdayKey),
      gender: prefs.getString(profileLocalGenderKey),
      avatarBase64: prefs.getString(profileLocalAvatarBase64Key),
    );
  }
}

class _LocalProfileCache {
  const _LocalProfileCache({
    this.displayName,
    this.phone,
    this.birthday,
    this.gender,
    this.avatarBase64,
  });

  final String? displayName;
  final String? phone;
  final String? birthday;
  final String? gender;
  final String? avatarBase64;
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 0)),
  ];
  String? _localDisplayName;
  String? _localPhone;
  String? _localBirthday;
  String? _localGender;
  String? _localAvatarBase64;
  String _preferredLanguage = 'English';
  String _preferredRegion = 'Singapore';

  @override
  void initState() {
    super.initState();
    _hydrateLocalProfile();
  }

  Future<void> _hydrateLocalProfile() async {
    final localProfile =
        await ref.read(profileRepositoryProvider).getLocalProfileDetails();
    final prefs = await SharedPreferences.getInstance();

    final savedLanguage =
        (prefs.getString(profilePreferredLanguageKey) ?? '').trim();
    final savedRegion =
        (prefs.getString(profilePreferredRegionKey) ?? '').trim();

    if (!mounted) return;
    setState(() {
      _localDisplayName = localProfile.displayName;
      _localPhone = localProfile.phone;
      _localBirthday = localProfile.birthday;
      _localGender = localProfile.gender;
      _localAvatarBase64 = localProfile.avatarBase64;
      _preferredLanguage = savedLanguage.isEmpty ? 'English' : savedLanguage;
      _preferredRegion = savedRegion.isEmpty ? 'Singapore' : savedRegion;
    });
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label: Coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openWishlist() async {
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const WishlistPage()));
    } catch (_) {
      _showComingSoon('Wishlist');
    }
  }

  Future<void> _openEditProfileScreen({
    required UserProfile? profile,
    required String initialDisplayName,
    required String initialPhone,
    required String initialBirthday,
    required String initialGender,
    required String? initialAvatarBase64,
    required String initialAvatarUrl,
  }) async {
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) => EditProfileScreen(
              initialDisplayName: initialDisplayName,
              initialPhone: initialPhone,
              initialBirthday: initialBirthday,
              initialGender: initialGender,
              initialAvatarBase64: initialAvatarBase64,
              initialAvatarUrl: initialAvatarUrl,
              receivesOffers: profile?.receivesOffers ?? false,
            ),
      ),
    );

    if (didUpdate == true) {
      await _hydrateLocalProfile();
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC80101),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      context.go(RegisterScreen.routePath);
    }
  }

  Future<void> _openLanguageRegionScreen() async {
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) => LanguageRegionScreen(
              initialLanguage: _preferredLanguage,
              initialRegion: _preferredRegion,
            ),
      ),
    );

    if (didUpdate == true) {
      await _hydrateLocalProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(profileProvider);

    final authStatus = authState.valueOrNull;
    final profile = profileAsync.valueOrNull;

    final user = authStatus is Authenticated ? authStatus.user : null;

    final localDisplayName = (_localDisplayName ?? '').trim();
    final localPhone = (_localPhone ?? '').trim();
    final localBirthday = (_localBirthday ?? '').trim();
    final localGender = (_localGender ?? '').trim();
    final remoteDisplayName = (profile?.displayName ?? user?.name ?? '').trim();
    final remotePhone = (profile?.phone ?? user?.phone ?? '').trim();
    final remoteBirthday = (profile?.birthday ?? '').trim();
    final remoteGender = (profile?.gender ?? '').trim();

    final displayName =
        localDisplayName.isNotEmpty
            ? localDisplayName
            : (remoteDisplayName.isNotEmpty ? remoteDisplayName : 'D.LAB User');

    final email = (user?.email ?? '').trim();
    final phone = localPhone.isNotEmpty ? localPhone : remotePhone;
    final birthday = localBirthday.isNotEmpty ? localBirthday : remoteBirthday;
    final gender =
        localGender.isNotEmpty
            ? localGender
            : (remoteGender.isNotEmpty ? remoteGender : 'Prefer not to say');
    final subIdentity =
        email.isNotEmpty ? email : (phone.isNotEmpty ? phone : '@dlab_user');

    final avatarUrl = (profile?.avatarUrl ?? user?.avatar ?? '').trim();
    final avatarBase64 = (_localAvatarBase64 ?? '').trim();
    final languageSubtitle = '$_preferredLanguage, $_preferredRegion';

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const _PageHeading(title: 'Profile'),
            const SizedBox(height: 20),
            _ProfileHeaderCard(
              displayName: displayName,
              subtitle: subIdentity,
              avatarUrl: avatarUrl,
              avatarBase64: avatarBase64.isEmpty ? null : avatarBase64,
            ),
            const SizedBox(height: 15),
            _SectionCard(
              minHeight: 220,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 8, bottom: 8),
                  child: _SectionHeader(title: 'Order Management'),
                ),
                _ProfileMenuTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'My Orders',
                  subtitle: 'Track, return, buy again',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MyOrdersScreen(),
                      ),
                    );
                  },
                ),
                _ProfileMenuTile(
                  icon: Icons.assignment_return_outlined,
                  title: 'Return & Cancellation',
                  subtitle: 'Start and track returns',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OrderReturnScreen(),
                      ),
                    );
                  },
                ),
                _ProfileMenuTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'Track Shipment',
                  subtitle: 'See package status',
                  onTap: () => _showComingSoon('Track Shipment'),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              minHeight: 100,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 8, bottom: 8),
                  child: _SectionHeader(title: 'Shopping Tools'),
                ),
                _ProfileMenuTile(
                  icon: Icons.favorite_border,
                  title: 'Wishlist',
                  subtitle: 'Saved items waiting for you',
                  onTap: _openWishlist,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              minHeight: 353,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 8, bottom: 8),
                  child: _SectionHeader(title: 'Account Settings'),
                ),
                _ProfileMenuTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Name, phone, birthdate, gender',
                  onTap:
                      () => _openEditProfileScreen(
                        profile: profile,
                        initialDisplayName: displayName,
                        initialPhone: phone,
                        initialBirthday: birthday,
                        initialGender: gender,
                        initialAvatarBase64:
                            avatarBase64.isEmpty ? null : avatarBase64,
                        initialAvatarUrl: avatarUrl,
                      ),
                ),
                _ProfileMenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  subtitle: 'Home, Office',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SavedAddressesEmptyScreen(),
                      ),
                    );
                  },
                ),
                _ProfileMenuTile(
                  icon: Icons.security_outlined,
                  title: 'Security & Privacy',
                  subtitle: 'Password, 2FA, login history',
                  onTap: () => _showComingSoon('Security & Privacy'),
                ),
                _ProfileMenuTile(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  subtitle: 'Order updates, offers, reminders',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
                _ProfileMenuTile(
                  icon: Icons.language_outlined,
                  title: 'Language & Region',
                  subtitle: languageSubtitle,
                  onTap: _openLanguageRegionScreen,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              minHeight: 280,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 8, bottom: 8),
                  child: _SectionHeader(title: 'Support & About'),
                ),
                _ProfileMenuTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'FAQs, guides, tutorials',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
                _ProfileMenuTile(
                  icon: Icons.support_agent_outlined,
                  title: 'Contact Us',
                  subtitle: 'Chat, email, WhatsApp support',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ContactUsScreen(),
                      ),
                    );
                  },
                ),
                _ProfileMenuTile(
                  icon: Icons.info_outline,
                  title: 'About D.LAB',
                  subtitle: 'Design to Deliver',
                  onTap: () => _showComingSoon('About D.LAB'),
                ),
                _ProfileMenuTile(
                  icon: Icons.gavel_outlined,
                  title: 'Terms & Conditions',
                  subtitle: 'Privacy policy, returns policy',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _BusinessBanner(
              onSwitch: () => _showComingSoon('Business Account'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC80101),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _confirmLogout,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.displayName,
    required this.subtitle,
    required this.avatarUrl,
    required this.avatarBase64,
  });

  final String displayName;
  final String subtitle;
  final String avatarUrl;
  final String? avatarBase64;

  String get _initials {
    final parts =
        displayName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
    if (parts.isEmpty) return 'DL';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? memoryAvatar;
    final base64Value = (avatarBase64 ?? '').trim();
    if (base64Value.isNotEmpty) {
      try {
        memoryAvatar = base64Decode(base64Value);
      } catch (_) {
        memoryAvatar = null;
      }
    }

    final hasMemoryAvatar = memoryAvatar != null && memoryAvatar.isNotEmpty;
    final hasNetworkAvatar = avatarUrl.isNotEmpty;
    final hasAvatar = hasMemoryAvatar || hasNetworkAvatar;
    final ImageProvider<Object>? imageProvider =
        hasMemoryAvatar
            ? MemoryImage(memoryAvatar)
            : (hasNetworkAvatar ? NetworkImage(avatarUrl) : null);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x80CAE9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryColor),
        boxShadow: _ProfileScreenState._cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: _secondaryColor,
              shape: BoxShape.circle,
              image:
                  imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
            ),
            alignment: Alignment.center,
            child:
                hasAvatar
                    ? null
                    : Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryFontColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: _primaryColor,
                  size: 28,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, this.minHeight});

  final List<Widget> children;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _ProfileScreenState._cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight ?? 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F5FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: _primaryColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF181D27),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _mutedTextColor),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
      ],
    );
  }
}

class _BusinessBanner extends StatelessWidget {
  const _BusinessBanner({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(5),
        boxShadow: _ProfileScreenState._cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: SvgPicture.asset(
                'assets/icons/Frame 23380.svg',
                width: 34,
                height: 34,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch to Business Account',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Get bulk pricing, RFQs & manufacturing access',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 98,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onSwitch,
              child: const Text(
                'Upgrade',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
