import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/provider/auth_providers.dart';

const _primaryColor = Color(0xFF1B4965);
const _secondaryColor = Color(0xFF62B6CB);
const _mutedTextColor = Color(0xFF6B7280);
const _primaryFontColor = Color(0xFF111827);

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orderNumberController = TextEditingController();
  final _messageController = TextEditingController();

  static const _subjectOptions = [
    'Order Inquiry',
    'Return & Cancellation',
    'Shipping & Delivery',
    'Payment & Billing',
    'Account & Profile',
    'Technical Support',
  ];

  String _selectedSubject = _subjectOptions.first;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
    _messageController.addListener(_onFormChanged);
    _prefillFields();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _messageController.removeListener(_onFormChanged);
    _nameController.dispose();
    _emailController.dispose();
    _orderNumberController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedSubject.trim().isNotEmpty &&
        _messageController.text.trim().isNotEmpty;
  }

  Future<void> _prefillFields() async {
    final prefs = await SharedPreferences.getInstance();
    final localName =
        (prefs.getString(profileLocalDisplayNameKey) ?? '').trim();
    final userEmail =
        (Supabase.instance.client.auth.currentUser?.email ?? '').trim();

    if (!mounted) return;

    if (localName.isNotEmpty) {
      _nameController.text = localName;
    }

    if (userEmail.isNotEmpty) {
      _emailController.text = userEmail;
    }

    setState(() {});
  }

  void _onFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSendMessage() {
    if (!_isFormValid) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Send Message: Coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFFF5500)),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF999999),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                            'Contact Us',
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
                    const SizedBox(height: 40),
                    _fieldLabel('Your Name', required: true),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _nameController,
                      decoration: _fieldDecoration('Alex Chen'),
                    ),
                    const SizedBox(height: 34),
                    _fieldLabel('Email Address'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration('alex.chen@email.com'),
                    ),
                    const SizedBox(height: 34),
                    _fieldLabel('Order Number (Optional)'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _orderNumberController,
                      decoration: _fieldDecoration('e.g DLAB-2025-2489'),
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('Subject', required: true),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _primaryColor,
                        size: 26,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      decoration: _fieldDecoration('Order Inquiry'),
                      items:
                          _subjectOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedSubject = value);
                      },
                    ),
                    const SizedBox(height: 34),
                    _fieldLabel('Message', required: true),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _messageController,
                      maxLines: 8,
                      minLines: 8,
                      decoration: _fieldDecoration(
                        'Please describe your issue here...',
                      ).copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _onSendMessage : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor:
                        _isFormValid ? _primaryColor : const Color(0xFF98A8B4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Send Message',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
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
                  color: _secondaryColor,
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
    final color = isActive ? _secondaryColor : const Color(0xFF676D75);
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
