import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the initial app experience while backend/auth is not yet finalized.
///
/// For now: show splash for a few seconds, then go to onboarding.
final onboardingFlowProvider = StateNotifierProvider<OnboardingFlowNotifier, OnboardingFlowState>((ref) {
  return OnboardingFlowNotifier();
});

enum OnboardingFlowState {
  /// Still showing the splash.
  splash,

  /// Move user to onboarding.
  onboarding,

  /// Onboarding finished (or skipped) and app can proceed normally.
  done,
}

class OnboardingFlowNotifier extends StateNotifier<OnboardingFlowState> {
  OnboardingFlowNotifier() : super(OnboardingFlowState.splash) {
    _start();
  }

  Timer? _timer;

  void _start() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) state = OnboardingFlowState.onboarding;
    });
  }

  /// Call when the user finishes onboarding or chooses to skip/continue.
  void markDone() {
    _timer?.cancel();
    state = OnboardingFlowState.done;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
