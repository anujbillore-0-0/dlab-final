import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'final_review_screen.dart';

enum DeliveryType { ship, pickup }

class PickupLocation {
  const PickupLocation({
    required this.id,
    required this.title,
    required this.address,
  });

  final String id;
  final String title;
  final String address;
}

class CheckoutAddress {
  const CheckoutAddress({
    required this.id,
    required this.name,
    required this.label,
    required this.address,
    required this.phone,
  });

  final String id;
  final String name;
  final String label;
  final String address;
  final String phone;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'address': address,
      'phone': phone,
    };
  }

  factory CheckoutAddress.fromMap(Map<String, dynamic> map) {
    return CheckoutAddress(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      label: map['label'] as String? ?? 'Home',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _addressesKey = 'checkout_addresses_v1';
  static const _selectedAddressKey = 'checkout_selected_address_v1';
  static const _deliveryTypeKey = 'checkout_delivery_type_v1';
  static const _selectedPickupKey = 'checkout_selected_pickup_v1';

  static const List<PickupLocation> _pickupLocations = <PickupLocation>[
    PickupLocation(
      id: 'pickup_ne',
      title: 'Pickup Locations (North East Singapore)',
      address:
          '25 Anchorvale Crescent Bellewaters Block, 25 Basement Carpark, Singapore, 544656',
    ),
    PickupLocation(
      id: 'pickup_central',
      title: 'Pickup Location (Central Region Singapore)',
      address:
          '25 Anchorvale Crescent Bellewaters Block, 25 Basement Carpark, Singapore, 544656',
    ),
  ];

  DeliveryType _deliveryType = DeliveryType.ship;
  List<CheckoutAddress> _addresses = const <CheckoutAddress>[];
  String? _selectedAddressId;
  String _selectedPickupId = _pickupLocations.first.id;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final rawDelivery = prefs.getString(_deliveryTypeKey);
    final delivery = rawDelivery == 'pickup' ? DeliveryType.pickup : DeliveryType.ship;

    final rawAddresses = prefs.getStringList(_addressesKey) ?? const <String>[];
    var addresses =
        rawAddresses
            .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
            .map(CheckoutAddress.fromMap)
            .where((item) => item.name.trim().isNotEmpty)
            .toList();

    if (addresses.isEmpty) {
      addresses = const <CheckoutAddress>[
        CheckoutAddress(
          id: 'default_home',
          name: 'Alex Chen',
          label: 'Home',
          address: '1901 Thornridge cir. shiloh, hawaii 81063',
          phone: '+65 9123 4567',
        ),
      ];
      await _persistAddresses(addresses);
    }

    final selectedId = prefs.getString(_selectedAddressKey) ?? addresses.first.id;
    final selectedPickup = prefs.getString(_selectedPickupKey) ?? _pickupLocations.first.id;

    if (!mounted) {
      return;
    }

    setState(() {
      _deliveryType = delivery;
      _addresses = addresses;
      _selectedAddressId = addresses.any((a) => a.id == selectedId) ? selectedId : addresses.first.id;
      _selectedPickupId =
          _pickupLocations.any((location) => location.id == selectedPickup)
              ? selectedPickup
              : _pickupLocations.first.id;
      _loading = false;
    });
  }

  Future<void> _persistAddresses(List<CheckoutAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = addresses.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_addressesKey, encoded);
  }

  Future<void> _setDeliveryType(DeliveryType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deliveryTypeKey, type == DeliveryType.ship ? 'ship' : 'pickup');
    setState(() {
      _deliveryType = type;
    });
  }

  Future<void> _setSelectedAddress(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAddressKey, id);
    setState(() {
      _selectedAddressId = id;
    });
  }

  Future<void> _setSelectedPickupLocation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedPickupKey, id);
    setState(() {
      _selectedPickupId = id;
    });
  }

  Future<void> _openAddressSheet({CheckoutAddress? initial}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final labelController = TextEditingController(text: initial?.label ?? 'Home');
    final addressController = TextEditingController(text: initial?.address ?? '');
    final phoneController = TextEditingController(text: initial?.phone ?? '');

    final result = await showModalBottomSheet<CheckoutAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                initial == null ? 'Add Address' : 'Edit Address',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              _field('Name', nameController),
              const SizedBox(height: 10),
              _field('Label (Home/Work)', labelController),
              const SizedBox(height: 10),
              _field('Address', addressController, maxLines: 2),
              const SizedBox(height: 10),
              _field('Phone', phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4965),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        addressController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required address fields.')),
                      );
                      return;
                    }

                    Navigator.of(context).pop(
                      CheckoutAddress(
                        id: initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        label: labelController.text.trim().isEmpty ? 'Home' : labelController.text.trim(),
                        address: addressController.text.trim(),
                        phone: phoneController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Save Address', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final updated = [..._addresses];
    final existingIndex = updated.indexWhere((item) => item.id == result.id);
    if (existingIndex >= 0) {
      updated[existingIndex] = result;
    } else {
      updated.add(result);
    }

    await _persistAddresses(updated);
    await _setSelectedAddress(result.id);
    setState(() {
      _addresses = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedAddress = _addresses.firstWhere(
      (address) => address.id == _selectedAddressId,
      orElse: () => _addresses.first,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4965), size: 24),
                  ),
                  const Expanded(
                    child: Text(
                      'Checkout',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: -0.4,
                        color: Color(0xFF0B1527),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Delivery Type',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => _setDeliveryType(DeliveryType.ship),
                child: _selectionCard(
                  isSelected: _deliveryType == DeliveryType.ship,
                  child: Row(
                    children: [
                      _radio(_deliveryType == DeliveryType.ship),
                      const SizedBox(width: 10),
                      _deliveryIcon('assets/images/ship.png', Icons.local_shipping_outlined),
                      const SizedBox(width: 10),
                      const Text('Ship', style: _bodyStyle),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => _setDeliveryType(DeliveryType.pickup),
                child: _selectionCard(
                  isSelected: _deliveryType == DeliveryType.pickup,
                  child: Row(
                    children: [
                      _radio(_deliveryType == DeliveryType.pickup),
                      const SizedBox(width: 10),
                      _deliveryIcon('assets/images/pickup.png', Icons.inventory_2_outlined),
                      const SizedBox(width: 10),
                      const Text('Pick up', style: _bodyStyle),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFDADADA), thickness: 0.5),
              const SizedBox(height: 20),
              if (_deliveryType == DeliveryType.ship) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivering Address',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openAddressSheet(),
                      child: const Text(
                        'Add Address',
                        style: TextStyle(color: Color(0xFFFF5500), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._addresses.map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _setSelectedAddress(address.id),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 7.3,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _radio(address.id == _selectedAddressId),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          address.name,
                                          style: _boldBodyStyle,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _tag(address.label),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address.address,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(address.phone, style: _bodyStyle),
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () => _openAddressSheet(initial: address),
                                    child: const Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Color(0xFFFF5500),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Pickup locations',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ..._pickupLocations.map(
                  (location) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      onTap: () => _setSelectedPickupLocation(location.id),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 7.3,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _radio(location.id == _selectedPickupId),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location.title,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    location.address,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFDADADA), thickness: 0.5),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4965),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_deliveryType == DeliveryType.ship && selectedAddress.id.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add/select a shipping address.')),
                      );
                      return;
                    }

                    if (_deliveryType == DeliveryType.pickup && _selectedPickupId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a pickup location.')),
                      );
                      return;
                    }

                    final selectedPickup = _pickupLocations.firstWhere(
                      (location) => location.id == _selectedPickupId,
                      orElse: () => _pickupLocations.first,
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => FinalReviewScreen(
                              deliveryType:
                                  _deliveryType == DeliveryType.ship
                                      ? ReviewDeliveryType.ship
                                      : ReviewDeliveryType.pickup,
                              shippingAddress:
                                  _deliveryType == DeliveryType.ship
                                      ? {
                                        'id': selectedAddress.id,
                                        'name': selectedAddress.name,
                                        'label': selectedAddress.label,
                                        'address': selectedAddress.address,
                                        'phone': selectedAddress.phone,
                                      }
                                      : null,
                              pickupTitle:
                                  _deliveryType == DeliveryType.pickup
                                      ? selectedPickup.title
                                      : null,
                              pickupAddress:
                                  _deliveryType == DeliveryType.pickup
                                      ? selectedPickup.address
                                      : null,
                            ),
                      ),
                    );
                  },
                  child: const Text(
                    'Place Order',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              _selectionCard(
                isSelected: true,
                height: 45,
                child: Row(
                  children: [
                    _radio(true),
                    const SizedBox(width: 10),
                    const Text('HitPay Payment', style: _bodyStyle),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _deliveryIcon(String asset, IconData fallback) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E9EE),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Image.asset(
          asset,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(fallback, color: const Color(0xFF1B4965), size: 24),
        ),
      ),
    );
  }

  Widget _selectionCard({required bool isSelected, required Widget child, double height = 70}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF62B6CB).withValues(alpha: 0.1),
        border: isSelected ? Border.all(color: const Color(0xFF62B6CB), width: 1) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget _radio(bool isOn) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1B4965), width: 1.25),
      ),
      child:
          isOn
              ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B4965),
                    shape: BoxShape.circle,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4965).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(29),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1B4965),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: Color(0xFF374151),
  );

  static const TextStyle _boldBodyStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: Color(0xFF374151),
  );
}
