import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/screens/register_screen.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  static const routePath = '/onboarding-2';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    final headingSize = width * 0.09;
    final bodySize = width * 0.04;

    // Keep CTA layer position unchanged.
    final bottomCtaHeight = height * 0.12;

    // Keep the image strictly in the lower half so it never collides with text.
    // Reserve enough space for the top text block.
    final topTextBlockHeight = height * 0.45;
    final availableImageHeight = (height - topTextBlockHeight - bottomCtaHeight).clamp(0.0, double.infinity);

    // Cap image height to the available lower-half area.
    final imageHeight = availableImageHeight;

    // Small spacing between image and CTA layer.
    const imageBottomMargin = 8.0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// 1️⃣ Full Blue Background
            Positioned.fill(
              child: Container(
                color: const Color(0xFFCAE9FF),
              ),
            ),

            /// Skip (top-right)
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
                    height: 1.2,
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            /// 2️⃣ Top Text Section
            Positioned(
              top: height * 0.10,
              left: width * 0.06,
              right: width * 0.06,
              child: Column(
                children: [
                  Text(
                    'Scale with B2B &\nCustom Manufacturing',
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
                    'Explore curated products across categories with transparent pricing, verified partners, and reliable delivery, designed for everyday buyers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: bodySize,
                      height: 1.4,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            /// 3️⃣ Bottom Image Layer (confined to lower half; never overlaps text)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomCtaHeight + imageBottomMargin,
              child: IgnorePointer(
                child: SizedBox(
                  height: (imageHeight - imageBottomMargin).clamp(0.0, double.infinity),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/images/image20.png',
                      width: width,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) {
                        // Prevent crash if asset is not added yet.
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),

            /// 4️⃣ Bottom CTA Layer (keep exact position)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomCtaHeight,
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
                        context.push('/onboarding-3');
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
