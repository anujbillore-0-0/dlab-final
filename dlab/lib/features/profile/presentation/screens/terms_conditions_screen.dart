import 'package:flutter/material.dart';

const _primaryColor = Color(0xFF1B4965);
const _mutedTextColor = Color(0xFF6B7280);
const _primaryFontColor = Color(0xFF111827);
const _dividerColor = Color(0xFFDADADA);

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const List<_TermsSection> _sections = [
    _TermsSection(
      title: '1. Introduction',
      body:
          'Welcome to D.LAB ("Design to Deliver"). By accessing or using our platform, you agree to be bound by these Terms & Conditions. Please read them carefully before using our services.',
    ),
    _TermsSection(
      title: '2. Account Registration',
      body:
          'To access certain features, you must create an account. You agree to provide accurate and complete information. You are responsible for maintaining the confidentiality of your account credentials.',
      bullets: [
        'You must be at least 18 years old to create an account',
        'You are responsible for all activities under your account',
        'Notify us immediately of any unauthorized use',
      ],
    ),
    _TermsSection(
      title: '3. Orders and Payments',
      body:
          'All orders are subject to acceptance and availability. Prices are listed in local currency and include applicable taxes unless stated otherwise.',
      bullets: [
        'Payment must be completed before order processing',
        'We accept credit cards, UPI, net banking, and COD',
        'Orders may be cancelled before shipping for full refund',
      ],
    ),
    _TermsSection(
      title: '4. Shipping and Delivery',
      body:
          'Delivery times are estimates and not guaranteed. We partner with trusted logistics providers across Singapore, Malaysia, Thailand, Indonesia, Vietnam, and Philippines.',
      bullets: [
        'Standard delivery: 3-5 business days',
        'Express delivery: 1-2 business days',
        'International shipping rates apply outside ASEAN',
      ],
    ),
    _TermsSection(
      title: '5. Returns and Refunds',
      body:
          'We offer a 30-day return policy for eligible items. Products must be in original condition with all tags and packaging.',
      bullets: [
        'Return requests must be initiated within 30 days of delivery',
        'Refunds are processed within 5-7 business days',
        'Some items (e.g., custom products) are non-returnable',
      ],
    ),
    _TermsSection(
      title: '6. Privacy Policy',
      body:
          'Your privacy is important to us. We collect and process personal data in accordance with our Privacy Policy, which explains how we handle your information.',
    ),
    _TermsSection(
      title: '7. B2B and Manufacturing Terms',
      body:
          'For business accounts, additional terms apply including MOQ requirements, bulk pricing, and manufacturing agreements. Please contact our B2B team for custom arrangements.',
    ),
    _TermsSection(
      title: '8. Limitation of Liability',
      body:
          'D.LAB shall not be liable for indirect, incidental, or consequential damages arising from use of our platform. Our total liability is limited to the amount paid for the applicable order.',
    ),
    _TermsSection(
      title: '9. Governing Law',
      body:
          'These terms are governed by the laws of Singapore. Any disputes shall be resolved in the courts of Singapore.',
    ),
    _TermsSection(
      title: '10. Changes to Terms',
      body:
          'We may update these terms from time to time. Continued use of the platform constitutes acceptance of the revised terms.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: _primaryColor,
                        size: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0B1527),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Last Updated: January 15, 2025',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: _dividerColor, thickness: 0.5),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._sections.map((section) => _TermsSectionBlock(section)),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 7.3,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: const Text(
                        'For questions about these terms, contact us at\nlegal@dlab.com',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _StaticBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _TermsSectionBlock extends StatelessWidget {
  const _TermsSectionBlock(this.section);

  final _TermsSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            section.body,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...section.bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 9),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection({
    required this.title,
    required this.body,
    this.bullets = const <String>[],
  });

  final String title;
  final String body;
  final List<String> bullets;
}

class _StaticBottomNav extends StatelessWidget {
  const _StaticBottomNav();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Container(
              height: 61,
              decoration: const BoxDecoration(color: _primaryFontColor),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Row(
              children: const [
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    isActive: true,
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Categories',
                    isActive: false,
                  ),
                ),
                Expanded(child: SizedBox.shrink()),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Cart',
                    isActive: false,
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    isActive: false,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF62B6CB),
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryFontColor, width: 4),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 33,
              color: _primaryFontColor,
              alignment: const Alignment(0, 0.35),
              child: Container(
                width: 147,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFB9C0C9),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF62B6CB) : const Color(0xFF676D75);
    return SizedBox(
      height: 74,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
