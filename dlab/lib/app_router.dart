import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/provider/auth_providers.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/screens/signup_verification_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/verification_screen.dart';
import 'features/auth/presentation/screens/profile_details_screen.dart';
import 'features/home/presentation/screens/dlabs_home_page.dart';
import 'features/onboarding/presentation/provider/onboarding_providers.dart';
import 'features/onboarding/presentation/screens/dlab_splash_screen.dart';
import 'features/onboarding/presentation/screens/mode_selection_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'features/onboarding/presentation/screens/onboarding_screen_2.dart';
import 'features/onboarding/presentation/screens/onboarding_screen_3.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: DLabSplashScreen.routePath,
    refreshListenable: _GoRouterRefreshStream(ref),
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: SignUpScreen.routePath,
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: SignupVerificationScreen.routePath,
        builder: (_, state) => const SignupVerificationScreen(),
      ),
      GoRoute(
        path: ForgotPasswordScreen.routePath,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: VerificationScreen.routePath,
        builder: (_, __) => const VerificationScreen(),
      ),
      GoRoute(
        path: ResetPasswordScreen.routePath,
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: DLabSplashScreen.routePath,
        builder: (_, __) => const DLabSplashScreen(),
      ),
      GoRoute(
        path: OnboardingScreen1.routePath,
        builder: (_, __) => const OnboardingScreen1(),
      ),
      GoRoute(
        path: OnboardingScreen2.routePath,
        builder: (_, __) => const OnboardingScreen2(),
      ),
      GoRoute(
        path: OnboardingScreen3.routePath,
        builder: (_, __) => const OnboardingScreen3(),
      ),
      GoRoute(
        path: ModeSelectionScreen.routePath,
        builder: (_, __) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: DLabsHomePage.routePath,
        builder: (_, __) => const DLabsHomePage(),
      ),
      GoRoute(
        path: ProfileDetailsScreen.routePath,
        builder: (_, __) => const ProfileDetailsScreen(),
      ),
    ],
    redirect: (context, state) {
      final flow = ref.read(onboardingFlowProvider);
      final authState = ref.read(authStateProvider);

      final location = state.matchedLocation;

      final isStaticSplash = location == DLabSplashScreen.routePath;
      final isOnboarding =
          location == OnboardingScreen1.routePath ||
          location == OnboardingScreen2.routePath ||
          location == OnboardingScreen3.routePath;

      final isAuth =
          location == LoginScreen.routePath ||
          location == RegisterScreen.routePath ||
          location == SignUpScreen.routePath ||
          location == SignupVerificationScreen.routePath ||
          location == ForgotPasswordScreen.routePath ||
          location == VerificationScreen.routePath ||
          location == ResetPasswordScreen.routePath;

      final isHome = location == DLabsHomePage.routePath;
      final isProfileDetails = location == ProfileDetailsScreen.routePath;

      // While auth is still resolving, don't redirect — wait for real state.
      if (authState.isLoading) return null;

      // Check if the user is authenticated or browsing as guest.
      final isAuthenticated = authState.valueOrNull is Authenticated;
      final isGuest = authState.valueOrNull is Guest;

      // Guest → go straight to home; profile-details is never shown for guests.
      if (isGuest && !isHome) return DLabsHomePage.routePath;

      if (isAuthenticated) {
        // User explicitly skipped profile setup this session → let them through.
        final skipped = ref.read(profileSkippedProvider);

        if (!skipped) {
          final profileState = ref.read(profileProvider);

          // Wait for profile fetch to complete before deciding.
          if (profileState.isLoading) return null;

          final profileComplete = profileState.valueOrNull?.isComplete ?? false;

          // Incomplete profile → must fill in details first.
          if (!profileComplete && !isProfileDetails) {
            return ProfileDetailsScreen.routePath;
          }
        }

        // Profile complete (or skipped) and arriving from auth/onboarding → home.
        if (isAuth || isOnboarding || isStaticSplash) {
          return DLabsHomePage.routePath;
        }

        return null;
      }

      // Once onboarding is completed, unauthenticated users should land on register.
      if (flow == OnboardingFlowState.done && !isAuth) {
        return RegisterScreen.routePath;
      }

      // Phase 1: show static splash for a few seconds.
      if (flow == OnboardingFlowState.splash) {
        return isStaticSplash ? null : DLabSplashScreen.routePath;
      }

      // Phase 2: after splash delay, default user to onboarding.
      // IMPORTANT: Don't redirect away from auth/home/profile-details screens.
      if (flow == OnboardingFlowState.onboarding) {
        if (!isOnboarding && !isAuth && !isHome && !isProfileDetails) {
          return OnboardingScreen1.routePath;
        }
      }

      // Flow done => no forced redirect.
      return null;
    },
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(onboardingFlowProvider, (_, __) => notifyListeners());
    ref.listen(profileProvider, (_, __) => notifyListeners());
    ref.listen(profileSkippedProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
