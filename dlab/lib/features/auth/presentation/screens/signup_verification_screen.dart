import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/auth_providers.dart';
import 'signup_screen.dart';

// ── Data passed from SignUpScreen via GoRouter extra ────────────────────────

class SignupData {
  const SignupData({
    required this.email,
    required this.name,
    required this.password,
  });

  final String email;
  final String name;
  final String password;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SignupVerificationScreen extends ConsumerStatefulWidget {
  const SignupVerificationScreen({super.key});

  static const routePath = '/signup-verify';

  @override
  ConsumerState<SignupVerificationScreen> createState() =>
      _SignupVerificationScreenState();
}

class _SignupVerificationScreenState
    extends ConsumerState<SignupVerificationScreen> {
  // 6 individual controllers + focus nodes for the OTP boxes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  SignupData? _signupData;

  // Resend cooldown
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is SignupData) {
        setState(() => _signupData = extra);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendCountdown = 0);
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final data = _signupData;
    if (data == null) return;

    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }

    await ref.read(authStateProvider.notifier).verifyOtpAndRegister(
          email: data.email,
          name: data.name,
          password: data.password,
          otp: _otp,
        );
  }

  Future<void> _resend() async {
    final data = _signupData;
    if (data == null) return;

    final error = await ref.read(authStateProvider.notifier).sendOtp(
          email: data.email,
          name: data.name,
          password: data.password,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      // Clear OTP boxes and restart timer
    for (final c in _controllers) {
      c.clear();
    }
      _focusNodes[0].requestFocus();
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent to your email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (prev, next) {
      next.whenOrNull(
        error: (err, _) {
          if (!mounted) return;
          final msg = err is Exception ? err.toString() : 'Verification failed';
          final display = msg.startsWith('Exception: ') ? msg.substring(11) : msg;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(display)));
        },
      );
    });

    final isLoading = state.isLoading;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.047),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Back button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go(SignUpScreen.routePath,
                        extra: _signupData?.email),
                    child: const Icon(Icons.arrow_back,
                        color: Color(0xFF1A1A1A), size: 24),
                  ),
                  const Icon(Icons.info_outline,
                      color: Color(0xFF374151), size: 24),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Verify your email',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.05 * 32,
                  color: Color(0xFF1B4965),
                  height: 1.0,
                ),
              ),

              const SizedBox(height: 8),

              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF808080),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                        text: "We've sent a 6-digit verification code to "),
                    TextSpan(
                      text: _signupData?.email ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1B4965),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                        text: '. Enter it below to confirm your account.'),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  nextFocus: i < 5 ? _focusNodes[i + 1] : null,
                  prevFocus: i > 0 ? _focusNodes[i - 1] : null,
                  onCompleted: i == 5 ? _verify : null,
                )),
              ),

              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF071F2E),
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : _verify,
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify & Create Account',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend code
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Resend code in ${_resendCountdown}s',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF808080),
                        ),
                      )
                    : GestureDetector(
                        onTap: isLoading ? null : _resend,
                        child: const Text(
                          'Resend code',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B4965),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF1B4965),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single OTP input box ──────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.prevFocus,
    this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final FocusNode? prevFocus;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final boxSize = (w - (w * 0.094) - (5 * 10)) / 6;

    return SizedBox(
      width: boxSize,
      height: boxSize * 1.15,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            prevFocus?.requestFocus();
          }
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1B4965),
                width: 1.5,
              ),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (nextFocus != null) {
                nextFocus!.requestFocus();
              } else {
                focusNode.unfocus();
                onCompleted?.call();
              }
            }
          },
        ),
      ),
    );
  }
}
