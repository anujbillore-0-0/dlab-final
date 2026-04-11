import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/cart_service.dart';
import '../../../../core/services/hitpay_service.dart';

enum ReviewDeliveryType { ship, pickup }

class FinalReviewScreen extends StatefulWidget {
  const FinalReviewScreen({
    super.key,
    required this.deliveryType,
    required this.shippingAddress,
    required this.pickupTitle,
    required this.pickupAddress,
  });

  final ReviewDeliveryType deliveryType;
  final Map<String, String>? shippingAddress;
  final String? pickupTitle;
  final String? pickupAddress;

  @override
  State<FinalReviewScreen> createState() => _FinalReviewScreenState();
}

class _FinalReviewScreenState extends State<FinalReviewScreen> {
  static const Color primaryColor = Color(0xFF1B4965);
  static const Color accentColor = Color(0xFFFF5500);
  static const Color textBlack = Color(0xFF000000);
  static const Color textDark = Color(0xFF0B1527);
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textLightGrey = Color(0xFF868E96);

  static const _addressesKey = 'checkout_addresses_v1';
  static const _selectedAddressKey = 'checkout_selected_address_v1';

  final CartService _cartService = CartService.instance;
  final HitPayService _hitPayService = HitPayService();

  List<CartProduct> _items = <CartProduct>[];
  bool _loading = true;
  bool _processingPayment = false;

  ReviewDeliveryType _deliveryType = ReviewDeliveryType.ship;
  Map<String, String>? _shippingAddress;
  String? _pickupTitle;
  String? _pickupAddress;

  @override
  void initState() {
    super.initState();
    _deliveryType = widget.deliveryType;
    _shippingAddress = widget.shippingAddress;
    _pickupTitle = widget.pickupTitle;
    _pickupAddress = widget.pickupAddress;
    _loadData();
  }

  Future<void> _loadData() async {
    await _cartService.initialize();
    final items = await _cartService.getAll();

    if (_shippingAddress == null && _deliveryType == ReviewDeliveryType.ship) {
      final loadedAddress = await _loadSelectedShippingAddress();
      _shippingAddress = loadedAddress;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<Map<String, String>?> _loadSelectedShippingAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getString(_selectedAddressKey);
    final rawAddresses = prefs.getStringList(_addressesKey) ?? const <String>[];

    final addresses =
        rawAddresses
            .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
            .toList();

    if (addresses.isEmpty) {
      return null;
    }

    final selected =
        addresses.firstWhere(
          (entry) => entry['id']?.toString() == selectedId,
          orElse: () => addresses.first,
        );

    return {
      'id': selected['id']?.toString() ?? '',
      'name': selected['name']?.toString() ?? '',
      'label': selected['label']?.toString() ?? 'Home',
      'address': selected['address']?.toString() ?? '',
      'phone': selected['phone']?.toString() ?? '',
    };
  }

  double get _itemTotal =>
      _items.fold<double>(0, (sum, item) => sum + (item.regularPrice * item.quantity));

  double get _discountTotal => _items.fold<double>(
    0,
    (sum, item) => sum + ((item.regularPrice - (item.salePrice ?? item.regularPrice)) * item.quantity).clamp(0, double.infinity),
  );

  double get _grandTotal => _itemTotal - _discountTotal;

  String _price(double value) => '₹${value.toStringAsFixed(0)}';

  Future<void> _removeCurrentAddress() async {
    final currentId = _shippingAddress?['id'] ?? '';
    if (currentId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final rawAddresses = prefs.getStringList(_addressesKey) ?? const <String>[];
    final addresses =
        rawAddresses
            .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
            .where((entry) => entry['id']?.toString() != currentId)
            .toList();

    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one address is required.')),
      );
      return;
    }

    final encoded = addresses.map((entry) => jsonEncode(entry)).toList();
    await prefs.setStringList(_addressesKey, encoded);
    await prefs.setString(_selectedAddressKey, addresses.first['id']?.toString() ?? '');

    final reloaded = await _loadSelectedShippingAddress();
    if (!mounted) {
      return;
    }

    setState(() {
      _shippingAddress = reloaded;
    });
  }

  Future<void> _removeItem(CartProduct item) async {
    await _cartService.remove(item.id);
    await _loadData();
  }

  Future<void> _continueToHitPay() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty. Add items before continuing.')),
      );
      return;
    }

    setState(() {
      _processingPayment = true;
    });

    try {
      final payment = await _hitPayService.createPaymentRequest(
        HitPayPaymentRequest(
          amount: _grandTotal,
          referenceNumber: 'DLAB-${DateTime.now().millisecondsSinceEpoch}',
          email: 'customer@example.com',
          name: _shippingAddress?['name'] ?? 'DLAB Customer',
          purpose: 'Order payment',
        ),
      );

      final url = Uri.tryParse(payment.url);
      if (url == null) {
        throw Exception('Invalid HitPay URL');
      }

      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Unable to open HitPay URL.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment init failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final itemCount = _items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Review',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textDark,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                _deliveryType == ReviewDeliveryType.ship ? 'Shipping Address' : 'Pickup location',
                actionText: 'Edit',
                onActionTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              _buildShadowCard(
                child: _deliveryType == ReviewDeliveryType.ship
                    ? _buildShippingAddressCard()
                    : _buildPickupCard(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                'payment method',
                actionText: 'Edit',
                onActionTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              _buildShadowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HitPay Payment',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: textLightGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildPasswordDot(),
                        const SizedBox(width: 8),
                        _buildPasswordDot(),
                        const SizedBox(width: 8),
                        _buildPasswordDot(),
                        const SizedBox(width: 12),
                        const Text(
                          '8553',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF212529),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items (${itemCount.toString().padLeft(2, '0')})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: textBlack,
                    ),
                  ),
                  const Text(
                    'Arrives by April 3 to April 9th',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildItemCard(item),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomSummaryCard(),
    );
  }

  Widget _buildShippingAddressCard() {
    final address = _shippingAddress;
    if (address == null) {
      return const Text(
        'No shipping address selected.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textMuted,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioButton(selected: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      address['name'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textBody,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildTag(address['label'] ?? 'Home'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                address['address'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address['phone'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: textBody,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildActionText('Edit', onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 20),
                  _buildActionText('Remove', onTap: _removeCurrentAddress),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickupCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioButton(selected: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pickupTitle ?? 'Pickup location',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: textBody,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _pickupAddress ?? '',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: textBlack,
          ),
        ),
        if (actionText != null)
          _buildActionText(
            actionText,
            onTap: onActionTap,
          ),
      ],
    );
  }

  Widget _buildShadowCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 7.3,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildItemCard(CartProduct item) {
    final displayImage =
        item.images.isNotEmpty ? item.images.first : (item.imageUrl ?? '');
    final displayPrice = item.salePrice ?? item.regularPrice;

    return _buildShadowCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: displayImage.isEmpty
                ? const Icon(Icons.laptop_mac, color: Colors.grey)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      displayImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.laptop_mac, color: Colors.grey),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          height: 1.3,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: textMuted, size: 20),
                      onSelected: (value) {
                        if (value == 'remove') {
                          _removeItem(item);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'remove',
                          child: Text('Remove item'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QTY: ${item.quantity}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: textBlack,
                      ),
                    ),
                    Text(
                      _price(displayPrice * item.quantity),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: textBlack,
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

  Widget _buildBottomSummaryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8.4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryRow('Item Total', _price(_itemTotal), isBold: false),
          const SizedBox(height: 12),
          _buildSummaryRow('Discount', '-${_price(_discountTotal)}', isBold: false),
          const SizedBox(height: 12),
          _buildSummaryRow('Delivery Free', '₹0', isBold: false),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFDADADA), thickness: 0.5),
          const SizedBox(height: 16),
          _buildSummaryRow('Grand Total', _price(_grandTotal), isBold: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: _processingPayment ? null : _continueToHitPay,
              child: Text(
                _processingPayment ? 'Opening HitPay...' : 'Continue',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {required bool isBold}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            fontSize: isBold ? 20 : 16,
            color: textDark,
            letterSpacing: -0.32,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            fontSize: isBold ? 20 : 16,
            color: primaryColor,
            letterSpacing: -0.32,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton({required bool selected}) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor, width: 1.25),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4965).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(29),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: primaryColor,
          letterSpacing: -0.28,
        ),
      ),
    );
  }

  Widget _buildActionText(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildPasswordDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF212529),
        shape: BoxShape.circle,
      ),
    );
  }
}
