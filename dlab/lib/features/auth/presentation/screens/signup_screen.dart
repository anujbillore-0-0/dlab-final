import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/auth_providers.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'signup_verification_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  static const routePath = '/signup';

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill email passed from RegisterScreen via GoRouter extra (plain String)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is String && extra.isNotEmpty) {
        _emailController.text = extra;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email    = _emailController.text.trim();
    final name     = _nameController.text.trim();
    final password = _passwordController.text;

    final error = await ref.read(authStateProvider.notifier).sendOtp(
      email: email,
      name: name,
      password: password,
    );

    if (!mounted) return;

    if (error != null) {
      if (error == 'EMAIL_EXISTS') {
        // Email already registered — redirect to login screen.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This email is already registered. Please log in.'),
            backgroundColor: Color(0xFF374151),
          ),
        );
        context.go(LoginScreen.routePath, extra: email);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    // Navigate to OTP verification screen, passing signup data as extra
    context.go(
      SignupVerificationScreen.routePath,
      extra: SignupData(email: email, name: name, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authStateProvider);

    // No longer listening to provider errors here — sendOtp returns error string directly.
    final isLoading = state.isLoading;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.047),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.go(RegisterScreen.routePath),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1A1A1A),
                        size: 24,
                      ),
                    ),
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF374151),
                      size: 24,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Text(
                  'Create your account',
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

                const Text(
                  "Let's get you started with DLab.",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF808080),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SignUpTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        obscure: false,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _SignUpTextField(
                        label: 'Email',
                        hint: 'Enter your email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        obscure: false,
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
                      ),

                      const SizedBox(height: 16),

                      _SignUpTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        obscure: true,
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return 'Password is required';
                          if (value.length < 8) {
                            return 'At least 8 characters required';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(value)) {
                            return 'Must contain at least 1 uppercase letter';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(value)) {
                            return 'Must contain at least 1 number';
                          }
                          if (!RegExp(
                            r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/]',
                          ).hasMatch(value)) {
                            return 'Must contain at least 1 special character';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),

                      const SizedBox(height: 24),

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
                                  'Create Account',
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

                const SizedBox(height: 40),

                Center(
                  child: GestureDetector(
                    onTap: () => context.go(LoginScreen.routePath),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF808080),
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: Color(0xFF1B4965),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF1B4965),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sign Up Text Field ────────────────────────────────────────────────────────

class _SignUpTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _SignUpTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    this.textInputAction,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<_SignUpTextField> createState() => _SignUpTextFieldState();
}

class _SignUpTextFieldState extends State<_SignUpTextField> {
  bool _hidden = true;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscure ? _hidden : false,
          onFieldSubmitted: widget.onFieldSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            final result = widget.validator?.call(value);
            if (result != _errorText) setState(() => _errorText = result);
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
              horizontal: 20,
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
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: hasError
                          ? const Color(0xFFED1010)
                          : const Color(0xFF999999),
                      size: 22,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : hasError
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
            _errorText!,
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
