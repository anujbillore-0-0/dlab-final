import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/auth_providers.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';

/// Screen that collects the 6-digit OTP sent to the user's email during the
/// forgot-password flow. On successful verification a Supabase session is
/// created so that the next screen can call `updateUser` to set the new
/// password.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  static const routePath = '/forgot-password-verify';

  @override
  ConsumerState<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  // 6 individual controllers + focus nodes for the OTP boxes.
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String? _email;
  bool _isVerifying = false;

  // Resend cooldown.
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is String && extra.isNotEmpty) {
        setState(() => _email = extra);
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
    if (_email == null || _email!.isEmpty) return;
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }
    if (_isVerifying) return;

    setState(() => _isVerifying = true);
    try {
      final error = await ref
          .read(authStateProvider.notifier)
          .verifyPasswordResetOtp(email: _email!, otp: _otp);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }

      // OTP verified – navigate to reset-password screen.
      context.go(ResetPasswordScreen.routePath, extra: _email);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_email == null || _email!.isEmpty) return;

    final error = await ref
        .read(authStateProvider.notifier)
        .sendPasswordResetOtp(_email!);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A new code has been sent to your email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // ── Top bar ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go(ForgotPasswordScreen.routePath),
                    child: const Icon(Icons.arrow_back,
                        color: Color(0xFF1A1A1A), size: 24),
                  ),
                  const Icon(Icons.info_outline,
                      color: Color(0xFF374151), size: 24),
                ],
              ),

              const SizedBox(height: 24),

              // ── Title ────────────────────────────────────────────────────
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

              // ── Subtitle ─────────────────────────────────────────────────
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
                        text:
                            "We've sent a 6-digit verification code to "),
                    TextSpan(
                      text: _email ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1B4965),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                        text:
                            '. Enter it below to reset your password.'),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── OTP boxes ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    nextFocus: i < 5 ? _focusNodes[i + 1] : null,
                    prevFocus: i > 0 ? _focusNodes[i - 1] : null,
                    onCompleted: i == 5 ? _verify : null,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Verify button ────────────────────────────────────────────
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
                  onPressed: _isVerifying ? null : _verify,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Resend code ──────────────────────────────────────────────
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
                        onTap: _isVerifying ? null : _resend,
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
