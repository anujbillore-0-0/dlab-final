import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../provider/auth_providers.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const routePath = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _checkingEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Checks whether the email already has a Supabase account:
  ///   - already exists → go to LoginScreen (sign-in flow)
  ///   - new email      → go to SignUpScreen (sign-up flow)
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    if (_checkingEmail || ref.read(authStateProvider).isLoading) return;

    setState(() => _checkingEmail = true);
    try {
      final exists =
          await ref.read(authStateProvider.notifier).checkEmailExists(email);

      if (!mounted) return;

      if (exists) {
        context.go(LoginScreen.routePath, extra: email);
      } else {
        context.go(SignUpScreen.routePath, extra: email);
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFED1010),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (prev, next) {
      next.whenOrNull(
        error: (err, _) {
          if (!mounted) return;
          final msg = err is Exception ? err.toString() : 'Something went wrong';
          final display =
              msg.startsWith('Exception: ') ? msg.substring(11) : msg;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(display)));
        },
      );
    });

    final isLoading = state.isLoading || _checkingEmail;
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCAE9FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top: info icon + title + subtitle ───────────────────────
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      right: w * 0.047,
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(0xFF374151),
                        size: 24,
                      ),
                    ),
                    Positioned(
                      top: h * 0.051,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Text(
                            'Welcome to DLab',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: w * 0.075,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.05 * (w * 0.075),
                              color: const Color(0xFF1B4965),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign In or Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: w * 0.037,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF808080),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom: social buttons + email + CTA + guest ────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.047),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Google + Apple side by side
                            Row(
                              children: [
                                Expanded(
                                  child: _OutlinedSocialButton(
                                    icon: SvgPicture.asset(
                                      'assets/icons/google_logo.svg',
                                      height: 24,
                                      width: 24,
                                    ),
                                    label: 'Continue with Google',
                                    onPressed: isLoading
                                        ? null
                                        : () => ref
                                            .read(authStateProvider.notifier)
                                            .signInWithGoogle(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _OutlinedSocialButton(
                                    icon: const Icon(
                                      Icons.apps_rounded,
                                      size: 24,
                                      color: Color(0xFF386BF6),
                                    ),
                                    label: 'Continue with Apple',
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Apple login coming soon'),
                                            ));
                                          },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Facebook full width
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1877F2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text('Facebook login coming soon'),
                                        ));
                                      },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.facebook,
                                        color: Colors.white, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Continue with Facebook',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Or divider
                            const Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Color(0xFFE6E6E6),
                                        thickness: 1)),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'Or',
                                    style: TextStyle(
                                      fontFamily: 'GeneralSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF808080),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Color(0xFFE6E6E6),
                                        thickness: 1)),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Email label
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1A1A1A),
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Email field
                            CustomTextField(
                              hint:
                                  'Enter email to sign in or create your account',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return 'Email is required';
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            const SizedBox(height: 20),

                            // Continue button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF071F2E),
                                  disabledBackgroundColor:
                                      const Color(0xFFCCCCCC),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: isLoading ? null : _submit,
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
                                        'Continue',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFFFFFFFF),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Continue as guest
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: GestureDetector(
                            onTap: () => ref
                                .read(authStateProvider.notifier)
                                .continueAsGuest(),
                            child: const Text(
                              'Continue as guest',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF808080),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF808080),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ── Outlined Social Button ────────────────────────────────────────────────────

class _OutlinedSocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  const _OutlinedSocialButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Text Field ─────────────────────────────────────────────────────────

class CustomTextField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.textInputAction,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            final result = widget.validator?.call(value);
            if (result != errorText) {
              setState(() => errorText = result);
            }
          },
          validator: (_) => null,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1A1A1A),
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF999999),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 14,
            ),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFED1010)
                    : const Color(0xFFE6E6E6),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFED1010)
                    : const Color(0xFFE6E6E6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFED1010)
                    : const Color(0xFF1B4965),
                width: 1.2,
              ),
            ),
            suffixIcon: hasError
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.error_outline,
                      color: Color(0xFFED1010),
                      size: 22,
                    ),
                  )
                : null,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFED1010),
            ),
          ),
        ],
      ],
    );
  }
}