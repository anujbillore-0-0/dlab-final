import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/provider/auth_providers.dart';

const _primaryColor = Color(0xFF1B4965);
const _secondaryColor = Color(0xFF62B6CB);
const _mutedTextColor = Color(0xFF6B7280);
const _primaryFontColor = Color(0xFF111827);
const savedAddressesStorageKey = 'profile_saved_addresses';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key, this.initialAddress, this.editIndex});

  final Map<String, dynamic>? initialAddress;
  final int? editIndex;

  bool get isEditMode => initialAddress != null && editIndex != null;

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _fullNameController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '1');
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();

  static const _cityOptions = [
    'Amsterdam',
    'Bangalore',
    'Bangkok',
    'Barcelona',
    'Beijing',
    'Berlin',
    'Bogota',
    'Boston',
    'Brisbane',
    'Brussels',
    'Budapest',
    'Cairo',
    'Calgary',
    'Cape Town',
    'Chennai',
    'Chicago',
    'Copenhagen',
    'Dallas',
    'Delhi',
    'Dubai',
    'Dublin',
    'Frankfurt',
    'Geneva',
    'Guangzhou',
    'Hanoi',
    'Hong Kong',
    'Houston',
    'Istanbul',
    'Jakarta',
    'Johor Bahru',
    'Karachi',
    'Kuala Lumpur',
    'Kyoto',
    'Lagos',
    'Lima',
    'Lisbon',
    'London',
    'Los Angeles',
    'Madrid',
    'Manila',
    'Melbourne',
    'Mexico City',
    'Milan',
    'Montreal',
    'Mumbai',
    'Munich',
    'Nairobi',
    'New York',
    'Osaka',
    'Oslo',
    'Paris',
    'Perth',
    'Phnom Penh',
    'Prague',
    'Pune',
    'Quebec City',
    'Rome',
    'San Francisco',
    'Santiago',
    'Sao Paulo',
    'Seoul',
    'Shanghai',
    'Shenzhen',
    'Singapore',
    'Stockholm',
    'Sydney',
    'Taipei',
    'Tokyo',
    'Toronto',
    'Vancouver',
    'Vienna',
    'Warsaw',
    'Washington, D.C.',
    'Wellington',
    'Zurich',
    // Singapore planning areas
    'Ang Mo Kio',
    'Bedok',
    'Bishan',
    'Bukit Batok',
    'Bukit Merah',
    'Bukit Panjang',
    'Bukit Timah',
    'Choa Chu Kang',
    'Clementi',
    'Geylang',
    'Hougang',
    'Jurong East',
    'Jurong West',
    'Kallang',
    'Marine Parade',
    'Pasir Ris',
    'Punggol',
    'Queenstown',
    'Sembawang',
    'Sengkang',
    'Serangoon',
    'Tampines',
    'Toa Payoh',
    'Woodlands',
    'Yishun',
  ];

  static const _stateOptions = [
    // Singapore regions
    'Central Region (Singapore)',
    'East Region (Singapore)',
    'North Region (Singapore)',
    'North-East Region (Singapore)',
    'West Region (Singapore)',
    // Malaysia
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Labuan',
    'Malacca',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Putrajaya',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    // India
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    // Indonesia
    'Bali',
    'Banten',
    'Central Java',
    'DKI Jakarta',
    'East Java',
    'North Sumatra',
    'Riau',
    'South Sulawesi',
    'West Java',
    // Thailand
    'Bangkok',
    'Chiang Mai',
    'Chonburi',
    'Nakhon Ratchasima',
    'Phuket',
    // Philippines
    'Cebu',
    'Davao del Sur',
    'Metro Manila',
    'Pampanga',
    // Vietnam
    'Da Nang',
    'Hai Phong',
    'Hanoi',
    'Ho Chi Minh City',
    // United States
    'California',
    'Florida',
    'Illinois',
    'Massachusetts',
    'New Jersey',
    'New York',
    'Texas',
    'Washington',
    // Canada
    'Alberta',
    'British Columbia',
    'Manitoba',
    'Ontario',
    'Quebec',
  ];

  String _selectedCity = _cityOptions.first;
  String _selectedState = _stateOptions.first;
  String _saveAs = 'Home';
  bool _setAsDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _prefillFromSavedAddress(widget.initialAddress!);
    } else {
      _prefillFromProfile();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _fullNameController.text.trim().isNotEmpty &&
        _addressLine1Controller.text.trim().isNotEmpty;
  }

  Future<void> _prefillFromProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(profileLocalDisplayNameKey)?.trim() ?? '';
    final phone = prefs.getString(profileLocalPhoneKey)?.trim() ?? '';

    if (!mounted) return;

    if (name.isNotEmpty) {
      _fullNameController.text = name;
    }

    if (phone.isNotEmpty) {
      _prefillPhone(phone);
    }

    setState(() {});
  }

  void _prefillFromSavedAddress(Map<String, dynamic> json) {
    _fullNameController.text = (json['full_name'] ?? '').toString().trim();
    _prefillPhone((json['phone'] ?? '').toString());
    _addressLine1Controller.text =
        (json['address_line_1'] ?? '').toString().trim();
    _addressLine2Controller.text =
        (json['address_line_2'] ?? '').toString().trim();

    final city = (json['city'] ?? '').toString().trim();
    if (_cityOptions.contains(city)) {
      _selectedCity = city;
    }

    final state = (json['state'] ?? '').toString().trim();
    if (_stateOptions.contains(state)) {
      _selectedState = state;
    }

    final saveAs = (json['save_as'] ?? 'Home').toString().trim();
    if (saveAs == 'Home' || saveAs == 'Office' || saveAs == 'Other') {
      _saveAs = saveAs;
    }

    _setAsDefault = json['is_default'] == true;
  }

  void _prefillPhone(String rawPhone) {
    final cleaned = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.startsWith('+')) {
      final digits = cleaned.replaceFirst('+', '');
      if (digits.length > 10) {
        _countryCodeController.text = digits.substring(0, digits.length - 10);
        _phoneController.text = digits.substring(digits.length - 10);
      } else {
        _phoneController.text = digits;
      }
      return;
    }

    if (cleaned.length > 10) {
      _countryCodeController.text = cleaned.substring(0, cleaned.length - 10);
      _phoneController.text = cleaned.substring(cleaned.length - 10);
      return;
    }

    _phoneController.text = cleaned;
  }

  Future<void> _pickCity() async {
    final picked = await _pickFromSearchableOptions(
      title: 'Select City',
      options: _cityOptions,
      selectedValue: _selectedCity,
    );
    if (picked == null) return;
    setState(() => _selectedCity = picked);
  }

  Future<void> _pickState() async {
    final picked = await _pickFromSearchableOptions(
      title: 'Select State/Region',
      options: _stateOptions,
      selectedValue: _selectedState,
    );
    if (picked == null) return;
    setState(() => _selectedState = picked);
  }

  Future<String?> _pickFromSearchableOptions({
    required String title,
    required List<String> options,
    required String selectedValue,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final searchController = TextEditingController();
        var filtered = List<String>.from(options);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _primaryFontColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          final query = value.trim().toLowerCase();
                          setModalState(() {
                            filtered =
                                options
                                    .where(
                                      (item) =>
                                          item.toLowerCase().contains(query),
                                    )
                                    .toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final option = filtered[index];
                            final isSelected = option == selectedValue;
                            return ListTile(
                              dense: true,
                              title: Text(option),
                              trailing:
                                  isSelected
                                      ? const Icon(
                                        Icons.check,
                                        color: _primaryColor,
                                      )
                                      : null,
                              onTap: () => Navigator.of(context).pop(option),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAddress() async {
    if (!_isValid || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing =
          prefs.getStringList(savedAddressesStorageKey) ?? <String>[];

      if (_setAsDefault) {
        for (var i = 0; i < existing.length; i++) {
          try {
            final decoded = jsonDecode(existing[i]);
            if (decoded is Map<String, dynamic>) {
              decoded['is_default'] = false;
              existing[i] = jsonEncode(decoded);
            }
          } catch (_) {
            // Keep malformed entries unchanged.
          }
        }
      }

      final payload = _AddressPayload(
        fullName: _fullNameController.text.trim(),
        phone:
            '+${_countryCodeController.text.trim()}${_phoneController.text.trim()}',
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _selectedCity,
        state: _selectedState,
        saveAs: _saveAs,
        isDefault: _setAsDefault,
      );

      if (widget.isEditMode) {
        final editIndex = widget.editIndex!;
        if (editIndex >= 0 && editIndex < existing.length) {
          existing[editIndex] = jsonEncode(payload.toJson());
        } else {
          existing.add(jsonEncode(payload.toJson()));
        }
      } else {
        existing.add(jsonEncode(payload.toJson()));
      }

      await prefs.setStringList(savedAddressesStorageKey, existing);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Address saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to save address. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
          height: 1.4,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFFD92D20)),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFF999999),
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: _primaryColor,
                              size: 30,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.isEditMode ? 'Edit address' : 'Add address',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _primaryFontColor,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 34),
                      ],
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'Saved Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('Full Name', required: true),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _fullNameController,
                      decoration: _fieldDecoration('Alex Chen'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _label('Phone number'),
                    const SizedBox(height: 4),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
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
                                color: Color(0xFF999999),
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText: '1',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 14,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 40,
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
                                color: Color(0xFF999999),
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText: '12268 4876',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Address Line 1'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _addressLine1Controller,
                      decoration: _fieldDecoration('Alex Chen'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _label('Address Line 2 (Optional)'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _addressLine2Controller,
                      decoration: _fieldDecoration('Alex Chen'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('City'),
                              const SizedBox(height: 4),
                              _SearchPickerField(
                                value: _selectedCity,
                                onTap: _pickCity,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('State'),
                              const SizedBox(height: 4),
                              _SearchPickerField(
                                value: _selectedState,
                                onTap: _pickState,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label('Save as'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 11,
                      runSpacing: 10,
                      children: [
                        _SaveAsChip(
                          label: 'Home',
                          selected: _saveAs == 'Home',
                          onTap: () => setState(() => _saveAs = 'Home'),
                        ),
                        _SaveAsChip(
                          label: 'Office',
                          selected: _saveAs == 'Office',
                          onTap: () => setState(() => _saveAs = 'Office'),
                        ),
                        _SaveAsChip(
                          label: 'Other',
                          selected: _saveAs == 'Other',
                          onTap: () => setState(() => _saveAs = 'Other'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap:
                          () => setState(() => _setAsDefault = !_setAsDefault),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE6E6E6),
                              ),
                              borderRadius: BorderRadius.circular(2),
                              color:
                                  _setAsDefault
                                      ? _primaryColor
                                      : Colors.transparent,
                            ),
                            child:
                                _setAsDefault
                                    ? const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Set as default delivery address',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            (_isValid && !_isSaving) ? _saveAddress : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (_isValid && !_isSaving)
                                  ? _primaryColor
                                  : const Color(0xFFCCCCCC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Save Address',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _StaticBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _SearchPickerField extends StatelessWidget {
  const _SearchPickerField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          ],
        ),
      ),
    );
  }
}

class _SaveAsChip extends StatelessWidget {
  const _SaveAsChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFFFF5500) : Colors.transparent;
    final backgroundColor =
        selected ? const Color(0x1AFF5500) : const Color(0x1A1B4965);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(29),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0B1527),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            height: 1.1,
          ),
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

class _AddressPayload {
  const _AddressPayload({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.saveAs,
    required this.isDefault,
  });

  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String saveAs;
  final bool isDefault;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'save_as': saveAs,
      'is_default': isDefault,
    };
  }
}
