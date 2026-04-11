import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static splash screen (UI-only).
///
/// Note: Uses an asset `assets/d-lab-logo.png`. If the asset is not present,
/// the logo gracefully falls back to a text placeholder, preventing crashes.
class DLabSplashScreen extends StatelessWidget {
  const DLabSplashScreen({super.key});

  static const routePath = '/splash-static';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoWidth = (size.width * 0.7).clamp(220.0, 420.0);
    final logoHeight = (logoWidth * 0.32).clamp(70.0, 140.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFCAE9FF),
              Color(0xFF1B4965),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 4),
              Center(
                child: _LogoOrFallback(
                  path: 'assets/d-lab-logo.png',
                  width: logoWidth,
                  height: logoHeight,
                ),
              ),
              const Spacer(flex: 5),
              const Padding(
                padding: EdgeInsets.only(bottom: 32),
                child: CustomLoadingSpinner(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoOrFallback extends StatelessWidget {
  const _LogoOrFallback({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      color: Colors.white,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Text(
              'dLab',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        );
      },
    );
  }
}

class CustomLoadingSpinner extends StatefulWidget {
  const CustomLoadingSpinner({super.key});

  @override
  State<CustomLoadingSpinner> createState() => _CustomLoadingSpinnerState();
}

class _CustomLoadingSpinnerState extends State<CustomLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: SizedBox(
            width: 60.9,
            height: 60.9,
            child: CustomPaint(
              painter: GradientArcPainter(),
            ),
          ),
        );
      },
    );
  }
}

class GradientArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white,
        ],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(math.pi),
      ).createShader(rect);

    canvas.drawArc(rect, 0, 2 * math.pi * 0.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
