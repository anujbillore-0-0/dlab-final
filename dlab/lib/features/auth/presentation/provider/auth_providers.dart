import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/env/env_selector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/datasource/auth_remote_datasource.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repository/auth_repository.dart';

final loggerProvider = Provider<Logger>((ref) => Logger());
final envProvider = Provider((ref) => EnvSelector.current());

final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(envProvider);
  final logger = ref.watch(loggerProvider);
  return DioClient(env: env, logger: logger).dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final remote = AuthRemoteDataSourceImpl(dio);
  return AuthRepositoryImpl(remote);
});

const profileLocalDisplayNameKey = 'profile_local_display_name';
const profileLocalPhoneKey = 'profile_local_phone';
const profileLocalBirthdayKey = 'profile_local_birthday';
const profileLocalGenderKey = 'profile_local_gender';
const profileLocalAvatarBase64Key = 'profile_local_avatar_base64';

// ── Auth Status ──────────────────────────────────────────────────────────────

sealed class AuthStatus {
  const AuthStatus();
}

class AuthUnknown extends AuthStatus {
  const AuthUnknown();
}

class Authenticated extends AuthStatus {
  const Authenticated(this.user);
  final User user;
}

class Guest extends AuthStatus {
  const Guest();
}

class Unauthenticated extends AuthStatus {
  const Unauthenticated();
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class AuthStateNotifier extends StateNotifier<AsyncValue<AuthStatus>> {
  AuthStateNotifier(this._repo) : super(const AsyncValue.loading()) {
    // Listen to Supabase auth state changes.
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (_isBusy || _isPasswordResetFlow) return;

      switch (data.event) {
        case AuthChangeEvent.signedOut:
          unawaited(
            PushNotificationService.instance.clearUserTopicSubscription(),
          );
          state = const AsyncValue.data(Unauthenticated());
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          // Handles web OAuth redirect callback — session arrives here.
          if (data.session != null && state.valueOrNull is! Authenticated) {
            _syncAfterOAuthRedirect();
          }
        default:
          break;
      }
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<AuthState> _sub;
  bool _isBusy = false;
  bool _isPasswordResetFlow = false;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  // ── OAuth redirect callback (web Google sign-in) ────────────────────────
  // Called when the auth stream fires signedIn after a redirect.
  Future<void> _syncAfterOAuthRedirect() async {
    _isBusy = true;
    state = const AsyncValue.loading();
    try {
      final supaUser = Supabase.instance.client.auth.currentUser!;
      final provider = supaUser.appMetadata['provider'] as String? ?? 'google';
      state = AsyncValue.data(
        Authenticated(
          User(
            id: supaUser.id,
            supabaseUid: supaUser.id,
            email: supaUser.email ?? '',
            name: supaUser.userMetadata?['full_name'] as String?,
            authProvider: provider,
          ),
        ),
      );
      unawaited(
        PushNotificationService.instance.syncTopicSubscriptionsForCurrentUser(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isBusy = false;
    }
  }

  // ── Bootstrap (restore session on app start) ────────────────────────────

  Future<void> bootstrap() async {
    state = const AsyncValue.loading();
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      state = const AsyncValue.data(Unauthenticated());
      return;
    }

    // We have a valid Supabase session — the user IS authenticated.
    // Try to enrich from the backend, but fall back to Supabase user data
    // if the backend is unreachable.
    final supaUser = Supabase.instance.client.auth.currentUser!;
    state = AsyncValue.data(
      Authenticated(
        User(
          id: supaUser.id,
          supabaseUid: supaUser.id,
          email: supaUser.email ?? '',
          name: supaUser.userMetadata?['full_name'] as String?,
          authProvider: supaUser.appMetadata['provider'] as String? ?? 'email',
        ),
      ),
    );
    unawaited(
      PushNotificationService.instance.syncTopicSubscriptionsForCurrentUser(),
    );
  }

  // ── Check email exists (register screen) ────────────────────────────────
  // Calls the backend endpoint GET /api/auth/check-email?email=...
  // which uses the Supabase Admin API (service-role key) to look up the
  // user by email. This sends ZERO emails, has ZERO rate-limit risk,
  // and works regardless of Email Enumeration Protection setting.
  //
  // Returns true if email exists, false if new.
  // Throws Exception on network/connectivity errors.
  Future<bool> checkEmailExists(String email) async {
    final either = await _repo.checkEmail(email);
    return either.fold((failure) {
      final msg = failure.message.toLowerCase();
      // Connectivity / timeout errors → user-friendly message.
      if (msg.contains('no internet') ||
          msg.contains('timed out') ||
          msg.contains('timeout') ||
          msg.contains('connection') ||
          msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check your internet connection and try again.',
        );
      }
      // Any other backend error (4xx / 5xx) → surface the real message.
      throw Exception(
        failure.message.isNotEmpty
            ? failure.message
            : 'Failed to check email. Please try again.',
      );
    }, (exists) => exists);
  }

  // ── Send OTP (signup step 1) ─────────────────────────────────────────────
  // When "Confirm Email" is ON in Supabase, calling signUp() creates an
  // unconfirmed user and emails a 6-digit confirmation code (using the
  // {{ .Token }} placeholder in the "Confirm signup" email template).
  //
  // The OTP is verified later with OtpType.signup in verifyOtpAndRegister().
  //
  // Returns null on success.
  // Returns 'EMAIL_EXISTS' sentinel if email is already registered (caller
  // should redirect to login).
  // Returns error string on other failures.
  Future<String?> sendOtp({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already')) {
        return 'EMAIL_EXISTS';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Verify OTP + complete signup ─────────────────────────────────────────
  // Called from SignupVerificationScreen.
  // 1. Verify the OTP code with Supabase (signs in the session).
  // 2. Update the user's password + display name.
  // 3. Sync to PostgreSQL via backend.
  Future<void> verifyOtpAndRegister({
    required String email,
    required String name,
    required String password,
    required String otp,
  }) async {
    _isBusy = true;
    state = const AsyncValue.loading();
    try {
      // Step 1: verify the 6-digit email OTP.
      // Use OtpType.signup when "Confirm Email" is enabled in Supabase,
      // so this verifies the signup confirmation token (not the magic-link one).
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.signup,
      );

      if (res.user == null) {
        state = AsyncValue.error(
          Exception('OTP verification failed. Please try again.'),
          StackTrace.current,
        );
        return;
      }

      // Step 2: The password was already set during signUp(), so we only
      // need to ensure the display name is stored in user metadata.
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': name}),
      );

      final supaUser = Supabase.instance.client.auth.currentUser!;
      state = AsyncValue.data(
        Authenticated(
          User(
            id: supaUser.id,
            supabaseUid: supaUser.id,
            email: supaUser.email ?? email,
            name: name,
            authProvider: 'email',
          ),
        ),
      );
      unawaited(
        PushNotificationService.instance.syncTopicSubscriptionsForCurrentUser(),
      );
    } on AuthException catch (e) {
      state = AsyncValue.error(
        Exception(_mapSupabaseError(e)),
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isBusy = false;
    }
  }

  // ── Email login ──────────────────────────────────────────────────────────

  Future<void> login({required String email, required String password}) async {
    _isBusy = true;
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final supaUser = Supabase.instance.client.auth.currentUser!;
      state = AsyncValue.data(
        Authenticated(
          User(
            id: supaUser.id,
            supabaseUid: supaUser.id,
            email: supaUser.email ?? email,
            authProvider: 'email',
          ),
        ),
      );
      unawaited(
        PushNotificationService.instance.syncTopicSubscriptionsForCurrentUser(),
      );
    } on AuthException catch (e) {
      state = AsyncValue.error(
        Exception(_mapSupabaseError(e)),
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isBusy = false;
    }
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────
  // Web: uses Supabase OAuth redirect (google_sign_in doesn't support web).
  // Mobile: uses google_sign_in package → signInWithIdToken.

  Future<void> signInWithGoogle() async {
    _isBusy = true;
    state = const AsyncValue.loading();
    try {
      if (kIsWeb) {
        // On web, trigger Supabase's OAuth redirect flow.
        // The user will be redirected back to the app after authentication.
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'http://localhost:${Uri.base.port}',
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
        // After redirect comes back, the onAuthStateChange stream fires
        // and bootstrap() / the auth listener will handle the session.
        // We reset state here so the UI doesn't stay in loading forever.
        state = const AsyncValue.data(Unauthenticated());
        return;
      }

      // ── Mobile (Android / iOS) ─────────────────────────────────────────
      const webClientId =
          '787837219490-4a0oq0dncn03s5lv0qfhvkceaknh1jjs.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(Unauthenticated());
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        state = AsyncValue.error(
          Exception('Google sign-in failed: no ID token received'),
          StackTrace.current,
        );
        return;
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final supaUser = Supabase.instance.client.auth.currentUser!;
      state = AsyncValue.data(
        Authenticated(
          User(
            id: supaUser.id,
            supabaseUid: supaUser.id,
            email: supaUser.email ?? '',
            name: supaUser.userMetadata?['full_name'] as String?,
            authProvider: 'google',
          ),
        ),
      );
      unawaited(
        PushNotificationService.instance.syncTopicSubscriptionsForCurrentUser(),
      );
    } on AuthException catch (e) {
      state = AsyncValue.error(
        Exception(_mapSupabaseError(e)),
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isBusy = false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await PushNotificationService.instance.clearUserTopicSubscription();
    await GoogleSignIn().signOut();
    await Supabase.instance.client.auth.signOut();
    // onAuthStateChange stream will fire signedOut → sets Unauthenticated.
  }

  void continueAsGuest() {
    state = const AsyncValue.data(Guest());
  }

  void setUnauthenticated() {
    state = const AsyncValue.data(Unauthenticated());
  }

  // ── Forgot-password: send OTP to email ───────────────────────────────────
  // Returns null on success, error string on failure.
  Future<String?> sendPasswordResetOtp(String email) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      return null;
    } on AuthException catch (e) {
      return _mapSupabaseError(e);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('failed to fetch') ||
          msg.contains('socketexception') ||
          msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('timeout')) {
        return 'Cannot connect to server. Please check your internet connection.';
      }
      return 'Something went wrong. Please try again.';
    }
  }

  // ── Forgot-password: verify OTP ──────────────────────────────────────────
  // Verifies the 6-digit code. On success a session is created so that
  // updateUser (to set the new password) can be called immediately.
  //
  // Uses OtpType.magiclink because sendPasswordResetOtp() calls
  // signInWithOtp(shouldCreateUser: false) which generates a magic-link
  // type token. Supabase still sends a 6-digit code in the email template
  // when {{ .Token }} is used — the OtpType just tells verifyOTP which
  // token bucket to look up.
  //
  // Returns null on success, error string on failure.
  Future<String?> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      _isPasswordResetFlow = true;
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.magiclink,
      );
      if (res.user == null) {
        _isPasswordResetFlow = false;
        return 'Invalid verification code. Please try again.';
      }
      return null;
    } on AuthException catch (e) {
      _isPasswordResetFlow = false;
      return _mapSupabaseError(e);
    } catch (e) {
      _isPasswordResetFlow = false;
      return e.toString();
    }
  }

  // ── Forgot-password: set new password ────────────────────────────────────
  // Must be called AFTER verifyPasswordResetOtp succeeds (session active).
  // Returns null on success, error string on failure.
  Future<String?> resetPassword(String newPassword) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      // Sign out so the user must log in with the new password.
      _isPasswordResetFlow = false;
      await Supabase.instance.client.auth.signOut();
      return null;
    } on AuthException catch (e) {
      _isPasswordResetFlow = false;
      return _mapSupabaseError(e);
    } catch (e) {
      _isPasswordResetFlow = false;
      return e.toString();
    }
  }

  // ── Error mapping ────────────────────────────────────────────────────────

  String _mapSupabaseError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('wrong password')) {
      return 'Invalid email or password';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in';
    }
    if (msg.contains('user not found')) {
      return 'No account found with this email';
    }
    if (msg.contains('token') && msg.contains('invalid')) {
      return 'Incorrect verification code';
    }
    if (msg.contains('expired')) {
      return 'Verification code has expired. Please request a new one';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again';
    }
    return e.message;
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthStatus>>((ref) {
      return AuthStateNotifier(ref.watch(authRepositoryProvider));
    });

// ── Profile completeness ─────────────────────────────────────────────────────

/// In-memory flag — set to true when the user explicitly taps "Skip for now".
/// Resets on app restart; on the next cold start they'll be prompted again
/// if their profile is still incomplete.
final profileSkippedProvider = StateProvider<bool>((ref) => false);

/// Fetches the public.profiles row for the currently authenticated user.
/// Automatically re-runs whenever auth state changes.
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final authStatus = ref.watch(authStateProvider).valueOrNull;
  if (authStatus is! Authenticated) return null;

  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;

  try {
    final data =
        await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', uid)
            .maybeSingle(); // returns null instead of 406 when no row exists
    if (data == null) return null;
    return UserProfile.fromJson(data);
  } catch (_) {
    // Table missing or RLS error — treat as incomplete, don't crash.
    return null;
  }
});

/// Saves profile details to Supabase then invalidates [profileProvider] so
/// the router re-evaluates and sends the user to the home screen.
class SaveProfileService {
  const SaveProfileService(this._ref);
  final Ref _ref;

  Future<void> save({
    required String displayName,
    required String phone,
    required String birthday, // 'YYYY-MM-DD'
    required String gender,
    required bool receivesOffers,
    String? avatarUrl,
    String? avatarBase64,
  }) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    debugPrint('[SaveProfile] upserting profile for uid=$uid');

    final payload = <String, dynamic>{
      'id': uid,
      'display_name': displayName,
      'phone': phone,
      'birthday': birthday,
      'gender': gender,
      'receives_offers': receivesOffers,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      payload['avatar_url'] = avatarUrl.trim();
    }

    await Supabase.instance.client.from('profiles').upsert(payload);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(profileLocalDisplayNameKey, displayName);
    await prefs.setString(profileLocalPhoneKey, phone);
    await prefs.setString(profileLocalBirthdayKey, birthday);
    await prefs.setString(profileLocalGenderKey, gender);
    if (avatarBase64 != null) {
      if (avatarBase64.isEmpty) {
        await prefs.remove(profileLocalAvatarBase64Key);
      } else {
        await prefs.setString(profileLocalAvatarBase64Key, avatarBase64);
      }
    }

    debugPrint('[SaveProfile] upsert complete — invalidating profileProvider');

    // Refetch profile so router redirect logic re-runs.
    _ref.invalidate(profileProvider);
  }
}

final saveProfileProvider = Provider<SaveProfileService>(
  (ref) => SaveProfileService(ref),
);
