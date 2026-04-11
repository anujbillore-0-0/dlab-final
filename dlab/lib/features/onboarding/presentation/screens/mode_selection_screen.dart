import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/screens/register_screen.dart';
import '../provider/onboarding_providers.dart';

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  static const routePath = '/mode-selection';

  @override
  ConsumerState<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen> {
  int? _selectedIndex;

  void _selectMode(int index) {
    setState(() => _selectedIndex = index);
    // Requirement: clicking any mode goes to register.
    context.go(RegisterScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: height * 0.08),

                /// Logo
                Image.asset(
                  'assets/images/dlab_logo.png',
                  width: width * 0.5,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),

                SizedBox(height: height * 0.05),

                /// Heading
                Text(
                  'Choose Your Experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width * 0.07,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),

                SizedBox(height: height * 0.015),

                /// Subheading
                Text(
                  'Select your role to personalize your journey and access the right tools.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width * 0.04,
                    color: const Color(0xFF808080),
                    height: 1.4,
                  ),
                ),

                SizedBox(height: height * 0.05),

                /// Individual
                ModeCard(
                  imagePath: 'assets/images/individual.png',
                  title: 'Individual (B2C)',
                  description: 'Shop products, explore deals, and discover innovations curated for you.',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _selectMode(0),
                ),

                SizedBox(height: height * 0.025),

                /// Business
                ModeCard(
                  imagePath: 'assets/images/business.png',
                  title: 'Business (B2B)',
                  description: 'Access wholesale pricing, bulk orders, and enterprise solutions.',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _selectMode(1),
                ),

                SizedBox(height: height * 0.025),

                /// Innovator
                ModeCard(
                  imagePath: 'assets/images/innovator.png',
                  title: 'Innovator',
                  description: 'Collaborate on product development and explore manufacturing opportunities.',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _selectMode(2),
                ),

                SizedBox(height: height * 0.08),

                /// Continue as Guest
                GestureDetector(
                  onTap: () {
                    ref.read(onboardingFlowProvider.notifier).markDone();
                    context.go('/home');
                  },
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      color: Color(0xFF1B4965),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModeCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback? onTap;

  const ModeCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF5FB),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFF2182BE), width: 1.5) : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ]
              : const [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Circle Image
            Container(
              width: width * 0.14,
              height: width * 0.14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(width: width * 0.04),

            /// Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: width * 0.02),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: width * 0.035,
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
    );
  }
}
