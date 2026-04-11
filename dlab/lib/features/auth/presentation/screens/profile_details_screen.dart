import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../features/home/presentation/screens/dlabs_home_page.dart';
import '../provider/auth_providers.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  static const routePath = '/profile-details';

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _countryCodeController =
      TextEditingController(text: '1');

  String  _selectedGender = 'Prefer not to say';
  bool    _offersChecked   = false;
  bool    _isFormValid   = false;
  bool    _isSaving      = false;
  String? _saveError;

  // Raw DateTime so we can convert to ISO when saving.
  DateTime? _selectedDate;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController.addListener(_checkFormValidity);
    _phoneController.addListener(_checkFormValidity);
    _birthdayController.addListener(_checkFormValidity);
  }

  void _checkFormValidity() {
    setState(() {
      _isFormValid = _displayNameController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _birthdayController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B4965),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDate = picked;
      setState(() {
        _birthdayController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
      _checkFormValidity();
    }
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Gender',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              ..._genderOptions.map((gender) => ListTile(
                    title: Text(
                      gender,
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedGender == gender
                            ? const Color(0xFF1B4965)
                            : const Color(0xFF1A1A1A),
                        fontWeight: _selectedGender == gender
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: _selectedGender == gender
                        ? const Icon(Icons.check, color: Color(0xFF1B4965))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedGender = gender;
                      });
                      _checkFormValidity();
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _onContinue() async {
    if (!_isFormValid || _isSaving) return;

    setState(() {
      _isSaving  = true;
      _saveError = null;
    });

    try {
      // Convert MM/DD/YYYY → YYYY-MM-DD for Postgres date column.
      final iso = _selectedDate != null
          ? '${_selectedDate!.year}-'
            '${_selectedDate!.month.toString().padLeft(2, '0')}-'
            '${_selectedDate!.day.toString().padLeft(2, '0')}'
          : _birthdayController.text;

      await ref.read(saveProfileProvider).save(
            displayName:    _displayNameController.text.trim(),
            phone:          '${_countryCodeController.text}${_phoneController.text.trim()}',
            birthday:       iso,
            gender:         _selectedGender!,
            receivesOffers: _offersChecked,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully!'),
            backgroundColor: const Color(0xFF1B4965),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        context.go(DLabsHomePage.routePath);
      }
    } catch (e) {
      debugPrint('[ProfileDetails] save failed: $e');
      setState(() => _saveError = 'Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onSkip() {
    ref.read(profileSkippedProvider.notifier).state = true;
    context.go(DLabsHomePage.routePath);
  }

  // ── Greeting name ──────────────────────────────────────────────────────────

  String get _greetingName {
    final supaUser = Supabase.instance.client.auth.currentUser;
    final metaName = supaUser?.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) {
      return metaName.trim().split(' ').first;
    }
    final email = supaUser?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'there';
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text(
            'Fill in your profile details to help us personalize your shopping experience. All fields marked with * are required.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: Color(0xFF1B4965)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 40.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // ── Top bar: back + help ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _onSkip,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  color: Colors.transparent,
                                  child: const Icon(
                                    Icons.arrow_back,
                                    size: 22,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _showHelp,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  color: Colors.transparent,
                                  child: Icon(
                                    Icons.help_outline_rounded,
                                    size: 22,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Progress bar (3 equal segments) ──
                          Row(
                            children: List.generate(3, (i) {
                              return Expanded(
                                child: Container(
                                  margin:
                                      EdgeInsets.only(right: i < 2 ? 10 : 0),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 20),

                          // ── Heading ──
                          Text(
                            'Welcome, $_greetingName! 👋',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B4965),
                              letterSpacing: -1.6,
                              height: 1.0,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Help us personalize your shopping experience',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF808080),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Display Name ──
                          _buildLabel('Display name*'),
                          const SizedBox(height: 4),
                          _buildTextField(
                            controller: _displayNameController,
                            placeholder: 'Alex Chen',
                            keyboardType: TextInputType.name,
                          ),

                          const SizedBox(height: 16),

                          // ── Phone Number ──
                          _buildLabel('Phone number'),
                          const SizedBox(height: 4),
                          _buildPhoneField(),
                          const SizedBox(height: 4),
                          const Text(
                            'For order updates and delivery',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Birthday ──
                          _buildLabel('Birthday date'),
                          const SizedBox(height: 4),
                          _buildDateField(),

                          const SizedBox(height: 16),

                          // ── Gender ──
                          _buildLabel('Gender'),
                          const SizedBox(height: 4),
                          _buildGenderField(),

                          const SizedBox(height: 20),

                          // ── Offers checkbox ──
                          GestureDetector(
                            onTap: () => setState(
                                () => _offersChecked = !_offersChecked),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _offersChecked
                                        ? const Color(0xFF1B4965)
                                        : Colors.white,
                                    border: Border.all(
                                      color: _offersChecked
                                          ? const Color(0xFF1B4965)
                                          : const Color(0xFFE6E6E6),
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: _offersChecked
                                      ? const Icon(Icons.check,
                                          size: 12, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Send me personalized offers and recommendations',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF999999),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Save error ──
                          if (_saveError != null) ...[  
                            Text(
                              _saveError!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── Continue button ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  (_isFormValid && !_isSaving) ? _onContinue : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_isFormValid && !_isSaving)
                                    ? const Color(0xFF1B4965)
                                    : const Color(0xFFCCCCCC),
                                disabledBackgroundColor:
                                    const Color(0xFFCCCCCC),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Skip for now ──
                          Center(
                            child: GestureDetector(
                              onTap: _onSkip,
                              child: const Text(
                                'Skip for now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF808080),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
        height: 1.4,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE6E6E6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1A1A1A),
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: Color(0xFF999999),
            height: 1.4,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE6E6E6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 2),
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 20, maxWidth: 56),
              child: TextField(
                controller: _countryCodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText: '1',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF999999),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 2, vertical: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: const Color(0xFFE6E6E6)),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1A1A),
                height: 1.4,
              ),
              decoration: const InputDecoration(
                hintText: '12268 4876',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF999999),
                  height: 1.4,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E6E6)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _birthdayController.text.isEmpty
                    ? 'MM/DD/YYYY'
                    : _birthdayController.text,
                style: TextStyle(
                  fontSize: 16,
                  color: _birthdayController.text.isEmpty
                      ? const Color(0xFF999999)
                      : const Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: const Color(0xFF1B4965).withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return GestureDetector(
      onTap: _showGenderPicker,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E6E6)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedGender,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF1B4965),
            ),
          ],
        ),
      ),
    );
  }
}
