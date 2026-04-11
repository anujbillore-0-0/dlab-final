import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/provider/auth_providers.dart';

const _editPrimaryColor = Color(0xFF1B4965);
const _editBodyColor = Color(0xFF374151);

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialDisplayName,
    required this.initialPhone,
    required this.initialBirthday,
    required this.initialGender,
    required this.initialAvatarBase64,
    required this.initialAvatarUrl,
    required this.receivesOffers,
  });

  final String initialDisplayName;
  final String initialPhone;
  final String initialBirthday;
  final String initialGender;
  final String? initialAvatarBase64;
  final String? initialAvatarUrl;
  final bool receivesOffers;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '1');
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();

  static const _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  String _selectedGender = 'Prefer not to say';
  DateTime? _selectedDate;
  String? _avatarBase64;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.initialDisplayName;
    _selectedGender =
        widget.initialGender.trim().isEmpty
            ? 'Prefer not to say'
            : widget.initialGender;
    _avatarBase64 = widget.initialAvatarBase64;
    _prefillPhone(widget.initialPhone);
    _prefillBirthday(widget.initialBirthday);
  }

  void _prefillPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) {
      final digits = cleaned.replaceFirst('+', '');
      if (digits.length > 10) {
        _countryCodeController.text = digits.substring(0, digits.length - 10);
        _phoneController.text = digits.substring(digits.length - 10);
        return;
      }
      _phoneController.text = digits;
      return;
    }
    _phoneController.text = cleaned;
  }

  void _prefillBirthday(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    DateTime? parsed;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      parsed = DateTime.tryParse(trimmed);
    } else if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(trimmed)) {
      final parts = trimmed.split('/');
      parsed = DateTime.tryParse('${parts[2]}-${parts[0]}-${parts[1]}');
    }

    if (parsed == null) return;
    _selectedDate = parsed;
    _birthdayController.text = _formatDate(parsed);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _displayNameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _birthdayController.text.trim().isNotEmpty &&
        _selectedGender.trim().isNotEmpty;
  }

  Uint8List? get _avatarBytes {
    final base64 = _avatarBase64;
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  String _birthdayIsoValue() {
    if (_selectedDate != null) {
      final mm = _selectedDate!.month.toString().padLeft(2, '0');
      final dd = _selectedDate!.day.toString().padLeft(2, '0');
      return '${_selectedDate!.year}-$mm-$dd';
    }

    final text = _birthdayController.text.trim();
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
      final parts = text.split('/');
      return '${parts[2]}-${parts[0]}-${parts[1]}';
    }
    return text;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? DateTime(now.year - 18, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _editPrimaryColor,
              onPrimary: Colors.white,
              onSurface: _editBodyColor,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _birthdayController.text = _formatDate(picked);
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _avatarBase64 = base64Encode(bytes);
    });
  }

  Future<void> _showGenderPicker() async {
    await showModalBottomSheet<void>(
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
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Gender',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _editBodyColor,
                ),
              ),
              const SizedBox(height: 8),
              ..._genderOptions.map(
                (gender) => ListTile(
                  title: Text(
                    gender,
                    style: TextStyle(
                      color:
                          _selectedGender == gender
                              ? _editPrimaryColor
                              : _editBodyColor,
                      fontSize: 16,
                      fontWeight:
                          _selectedGender == gender
                              ? FontWeight.w600
                              : FontWeight.w400,
                    ),
                  ),
                  trailing:
                      _selectedGender == gender
                          ? const Icon(Icons.check, color: _editPrimaryColor)
                          : null,
                  onTap: () {
                    setState(() => _selectedGender = gender);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_isFormValid || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final countryCode = _countryCodeController.text.trim();
      final rawPhone = _phoneController.text.trim();
      final phone = '+$countryCode$rawPhone';

      await ref
          .read(saveProfileProvider)
          .save(
            displayName: _displayNameController.text.trim(),
            phone: phone,
            birthday: _birthdayIsoValue(),
            gender: _selectedGender,
            receivesOffers: widget.receivesOffers,
            avatarUrl: widget.initialAvatarUrl,
            avatarBase64: _avatarBase64,
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      setState(() => _isSaving = false);
      return;
    }
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
          height: 1.4,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFFD92D20)),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFF9CA3AF),
        height: 1.4,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _editPrimaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _editPrimaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _editPrimaryColor, width: 1.4),
      ),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarBytes;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: _editPrimaryColor,
                        size: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Help'),
                              content: const Text(
                                'Update your profile details to keep your account information current.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                    },
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: _editBodyColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE5EDF3),
                            ),
                            child:
                                avatar == null
                                    ? const Icon(
                                      Icons.person_rounded,
                                      size: 52,
                                      color: _editPrimaryColor,
                                    )
                                    : ClipOval(
                                      child: Image.memory(
                                        avatar,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _pickPhoto,
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 18,
                            ),
                            label: const Text('Change Profile Photo'),
                            style: TextButton.styleFrom(
                              foregroundColor: _editPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Name', required: true),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _editPrimaryColor,
                        height: 1.4,
                      ),
                      decoration: _inputDecoration('Alex Chen'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Phone number'),
                    const SizedBox(height: 4),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: _editPrimaryColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 16,
                              color: _editPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 2),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 56),
                            child: TextField(
                              controller: _countryCodeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                color: _editPrimaryColor,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                hintText: '1',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFFE6E6E6),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                color: _editPrimaryColor,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText: '12268 4876',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF9CA3AF),
                                  height: 1.4,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Birthdate'),
                    const SizedBox(height: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _pickDate,
                      child: IgnorePointer(
                        child: TextField(
                          controller: _birthdayController,
                          style: const TextStyle(
                            fontSize: 16,
                            color: _editPrimaryColor,
                            height: 1.4,
                          ),
                          decoration: _inputDecoration('MM/DD/YYYY').copyWith(
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: _editPrimaryColor,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Gender'),
                    const SizedBox(height: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _showGenderPicker,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: _editPrimaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedGender,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: _editPrimaryColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _editPrimaryColor,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isFormValid && !_isSaving) ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_isFormValid && !_isSaving)
                            ? _editPrimaryColor
                            : const Color(0xFFCCCCCC),
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isSaving
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
            ),
          ],
        ),
      ),
    );
  }
}
