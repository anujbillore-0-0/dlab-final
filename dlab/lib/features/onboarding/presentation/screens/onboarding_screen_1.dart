import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/screens/register_screen.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  static const routePath = '/onboarding-1';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    // Responsive font scaling
    final headingSize = width * 0.09; // ~40 on 428 width
    final bodySize = width * 0.04; // ~16 on 428 width

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// 1️⃣ Full Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/onboarding_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Prevent crash if asset is not added yet.
                  return const ColoredBox(color: Colors.white);
                },
              ),
            ),

            /// 2️⃣ Top Gradient Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: height * 0.45,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFCAE9FF),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),

            /// 3️⃣ Skip Button
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

            /// 4️⃣ Heading Text
            Positioned(
              top: height * 0.12,
              left: width * 0.05,
              right: width * 0.05,
              child: Text(
                'Discover Products,\nBuilt for You',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: headingSize,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.black,
                ),
              ),
            ),

            /// 5️⃣ Description Text
            Positioned(
              top: height * 0.24,
              left: width * 0.07,
              right: width * 0.07,
              child: Text(
                'Explore curated products across categories with transparent pricing, verified partners, and reliable delivery, designed for everyday buyers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: bodySize,
                  height: 1.4,
                  color: Colors.black,
                ),
              ),
            ),

            /// 6️⃣ Bottom Container
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: height * 0.12,
              child: Container(
                color: const Color(0xFFCAE9FF),
                child: Center(
                  child: SizedBox(
                    width: width * 0.9,
                    height: height * 0.065,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4965),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.push('/onboarding-2');
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
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
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
