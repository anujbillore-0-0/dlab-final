import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _primaryColor = Color(0xFF1B4965);
const _secondaryColor = Color(0xFF62B6CB);
const _mutedTextColor = Color(0xFF6B7280);
const _primaryFontColor = Color(0xFF111827);

const profilePreferredLanguageKey = 'profile_preferred_language';
const profilePreferredRegionKey = 'profile_preferred_region';

class LanguageRegionScreen extends StatefulWidget {
  const LanguageRegionScreen({
    super.key,
    required this.initialLanguage,
    required this.initialRegion,
  });

  final String initialLanguage;
  final String initialRegion;

  @override
  State<LanguageRegionScreen> createState() => _LanguageRegionScreenState();
}

class _LanguageRegionScreenState extends State<LanguageRegionScreen> {
  static const _languages = [
    'Arabic',
    'Bahasa Indonesia',
    'Bengali',
    'Bulgarian',
    'Burmese',
    'Catalan',
    'Chinese (Simplified)',
    'Chinese (Traditional)',
    'Croatian',
    'Czech',
    'Danish',
    'Dutch',
    'English',
    'Estonian',
    'Filipino',
    'Finnish',
    'French',
    'German',
    'Greek',
    'Gujarati',
    'Hebrew',
    'Hindi',
    'Hungarian',
    'Icelandic',
    'Italian',
    'Japanese',
    'Kannada',
    'Khmer',
    'Korean',
    'Lao',
    'Latvian',
    'Lithuanian',
    'Malay',
    'Malayalam',
    'Marathi',
    'Nepali',
    'Norwegian',
    'Persian',
    'Polish',
    'Portuguese',
    'Punjabi',
    'Romanian',
    'Russian',
    'Serbian',
    'Sinhala',
    'Slovak',
    'Slovenian',
    'Spanish',
    'Swedish',
    'Tamil',
    'Telugu',
    'Thai',
    'Turkish',
    'Ukrainian',
    'Urdu',
    'Vietnamese',
  ];

  static const _regions = [
    'Argentina',
    'Australia',
    'Austria',
    'Bangladesh',
    'Belgium',
    'Brazil',
    'Brunei',
    'Cambodia',
    'Canada',
    'Chile',
    'China',
    'Colombia',
    'Croatia',
    'Czech Republic',
    'Denmark',
    'Egypt',
    'Finland',
    'France',
    'Germany',
    'Greece',
    'Hong Kong',
    'Hungary',
    'India',
    'Indonesia',
    'Ireland',
    'Israel',
    'Italy',
    'Japan',
    'Kazakhstan',
    'Kenya',
    'Laos',
    'Luxembourg',
    'Malaysia',
    'Mexico',
    'Morocco',
    'Myanmar',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nigeria',
    'Norway',
    'Pakistan',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Saudi Arabia',
    'Serbia',
    'Singapore',
    'Slovakia',
    'South Africa',
    'South Korea',
    'Spain',
    'Sri Lanka',
    'Sweden',
    'Switzerland',
    'Taiwan',
    'Thailand',
    'Turkey',
    'UAE',
    'United Kingdom',
    'United States',
    'Vietnam',
  ];

  late String _selectedLanguage;
  late String _selectedRegion;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage =
        _languages.contains(widget.initialLanguage)
            ? widget.initialLanguage
            : 'English';
    _selectedRegion =
        _regions.contains(widget.initialRegion)
            ? widget.initialRegion
            : 'Singapore';
  }

  Future<void> _pickLanguage() async {
    final picked = await _pickOption(
      title: 'Select language',
      options: _languages,
      selectedValue: _selectedLanguage,
    );
    if (picked == null) return;
    setState(() => _selectedLanguage = picked);
  }

  Future<void> _pickRegion() async {
    final picked = await _pickOption(
      title: 'Select region',
      options: _regions,
      selectedValue: _selectedRegion,
    );
    if (picked == null) return;
    setState(() => _selectedRegion = picked);
  }

  Future<String?> _pickOption({
    required String title,
    required List<String> options,
    required String selectedValue,
  }) async {
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
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

  Future<void> _savePreferences() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(profilePreferredLanguageKey, _selectedLanguage);
      await prefs.setString(profilePreferredRegionKey, _selectedRegion);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                            'Language & Region',
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
                    const SizedBox(height: 30),
                    const Text(
                      'Preferred Language',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SelectionBox(
                      value: _selectedLanguage,
                      onTap: _pickLanguage,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Preferred Region',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SelectionBox(value: _selectedRegion, onTap: _pickRegion),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePreferences,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                          : const Text('Save Preferences'),
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

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.value, required this.onTap});

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
            horizontal: 20,
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
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
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
