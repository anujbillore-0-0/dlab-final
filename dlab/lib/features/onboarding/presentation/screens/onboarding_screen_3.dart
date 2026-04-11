import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/screens/register_screen.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  static const routePath = '/onboarding-3';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    final headingSize = width * 0.09;
    final bodySize = width * 0.04;

    // Responsive layout constants
    final bottomCtaHeight = height * 0.10; // slightly reduced
    final buttonBottomSpacing = height * 0.025;
    final imageOverlapShift = height * 0.10;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// 🔹 1️⃣ FULL BLUE BACKGROUND
            Positioned.fill(
              child: Container(
                color: const Color(0xFFCAE9FF),
              ),
            ),

            /// 🔹 2️⃣ SKIP BUTTON
            Positioned(
              top: height * 0.03,
              right: width * 0.05,
              child: GestureDetector(
                onTap: () {
                  context.go(RegisterScreen.routePath);
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: bodySize,
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            /// 🔹 3️⃣ TEXT SECTION
            Positioned(
              top: height * 0.10,
              left: width * 0.06,
              right: width * 0.06,
              child: Column(
                children: [
                  Text(
                    'Turn Ideas into Real Products',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: headingSize,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  Text(
                    'Have a product idea? Collaborate with manufacturers, bring concepts to life, and grow together through D.LAB’s innovation ecosystem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: bodySize,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 4️⃣ BLUE BACKGROUND FOR BUTTON (behind image)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomCtaHeight,
              child: Container(
                color: const Color(0xFFCAE9FF),
              ),
            ),

            /// 🔥 5️⃣ IMAGE (ABOVE BLUE BG, BELOW BUTTON)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomCtaHeight - (height * 0.03),
              top: height * 0.25,
              child: Transform.translate(
                offset: Offset(0, -imageOverlapShift),
                child: Image.asset(
                  'assets/images/image19.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

            /// 🔹 6️⃣ CONTINUE BUTTON (ALWAYS TOPMOST)
            Positioned(
              bottom: buttonBottomSpacing,
              left: width * 0.05,
              right: width * 0.05,
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4965),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.go(RegisterScreen.routePath);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: bodySize,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
