import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_address_screen.dart';

const _primaryColor = Color(0xFF1B4965);
const _secondaryColor = Color(0xFF62B6CB);
const _mutedTextColor = Color(0xFF6B7280);
const _primaryFontColor = Color(0xFF111827);

class SavedAddressesEmptyScreen extends StatefulWidget {
  const SavedAddressesEmptyScreen({super.key});

  @override
  State<SavedAddressesEmptyScreen> createState() =>
      _SavedAddressesEmptyScreenState();
}

class _SavedAddressesEmptyScreenState extends State<SavedAddressesEmptyScreen> {
  bool _isLoading = true;
  List<_SavedAddress> _addresses = <_SavedAddress>[];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(savedAddressesStorageKey) ?? <String>[];

    final parsed = <_SavedAddress>[];
    for (final raw in stored) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          parsed.add(_SavedAddress.fromJson(decoded));
        }
      } catch (_) {
        // Skip malformed entries.
      }
    }

    var selected = 0;
    if (parsed.isNotEmpty) {
      final defaultIndex = parsed.indexWhere((item) => item.isDefault);
      selected = defaultIndex >= 0 ? defaultIndex : 0;
    }

    if (!mounted) return;
    setState(() {
      _addresses = parsed;
      _selectedIndex = selected;
      _isLoading = false;
    });
  }

  Future<void> _openAddAddress() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddAddressScreen()));
    await _loadAddresses();
  }

  Future<void> _deleteAddress(int index) async {
    if (index < 0 || index >= _addresses.length) return;

    final updated = [..._addresses]..removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      savedAddressesStorageKey,
      updated.map((item) => jsonEncode(item.toJson())).toList(),
    );

    if (!mounted) return;
    setState(() {
      _addresses = updated;
      if (_selectedIndex >= _addresses.length) {
        _selectedIndex = _addresses.isEmpty ? 0 : _addresses.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: _primaryColor)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
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
                  const Expanded(
                    child: Text(
                      'Saved Address',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(21, 34, 21, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  _addresses.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              _NoAddressArtwork(),
                              SizedBox(height: 10),
                              Text(
                                'No Addresses Saved',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 40 / 2,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                width: 333,
                                child: Text(
                                  'Add your first address to make checkout\nfaster and easier',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _mutedTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        itemCount: _addresses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final item = _addresses[index];
                          final selected = index == _selectedIndex;
                          return _SavedAddressCard(
                            data: item,
                            selected: selected,
                            onSelect:
                                () => setState(() => _selectedIndex = index),
                            onEdit: () async {
                              final didSave = await Navigator.of(
                                context,
                              ).push<bool>(
                                MaterialPageRoute<bool>(
                                  builder:
                                      (_) => AddAddressScreen(
                                        initialAddress: item.toJson(),
                                        editIndex: index,
                                      ),
                                ),
                              );
                              if (didSave == true) {
                                await _loadAddresses();
                              }
                            },
                            onDelete: () => _deleteAddress(index),
                          );
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _openAddAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _addresses.isEmpty ? 'Add New Address' : 'Add Address',
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

class _NoAddressArtwork extends StatelessWidget {
  const _NoAddressArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 205,
      height: 205,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Positioned(
            bottom: 18,
            child: Icon(Icons.map_outlined, size: 132, color: _secondaryColor),
          ),
          Positioned(
            top: 0,
            child: Icon(
              Icons.location_on_rounded,
              size: 122,
              color: _primaryColor,
            ),
          ),
        ],
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

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.data,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final _SavedAddress data;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      data.addressLine1,
      if (data.addressLine2.isNotEmpty) data.addressLine2,
      data.city,
      data.state,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(10),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 25,
                color: _primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x1A1B4965),
                        borderRadius: BorderRadius.circular(29),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        data.saveAs,
                        style: const TextStyle(
                          color: _primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.phone,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    InkWell(
                      onTap: onEdit,
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Color(0xFFFF5500),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: onDelete,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFFF5500),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddress {
  const _SavedAddress({
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

  factory _SavedAddress.fromJson(Map<String, dynamic> json) {
    return _SavedAddress(
      fullName: (json['full_name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      addressLine1: (json['address_line_1'] ?? '').toString(),
      addressLine2: (json['address_line_2'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      saveAs: (json['save_as'] ?? 'Home').toString(),
      isDefault: json['is_default'] == true,
    );
  }

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
