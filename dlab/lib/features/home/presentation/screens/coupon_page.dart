import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppliedCouponResult {
  const AppliedCouponResult({
    required this.code,
    required this.discountPercentage,
  });

  final String code;
  final int discountPercentage;
}

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _applyingCodes = <String>{};
  final _supabase = Supabase.instance.client;

  List<_CouponItem> _coupons = <_CouponItem>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> rows = await _supabase
          .from('coupons')
          .select(
            'id,code,title,description,discount_percentage,usage_count,usage_limit,is_active',
          )
          .eq('is_active', true)
          .order('discount_percentage', ascending: false);

      final parsed =
          rows
              .whereType<Map<String, dynamic>>()
              .map(_CouponItem.fromJson)
              .where((item) => item.isActive && item.usageCount < item.usageLimit)
              .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _coupons = parsed;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load coupons right now.')),
      );
    }
  }

  Future<void> _applyCoupon(String code) async {
    if (_applyingCodes.contains(code)) return;

    setState(() => _applyingCodes.add(code));
    try {
      final normalizedCode = code.trim().toUpperCase();

      final dynamic currentRow = await _supabase
          .from('coupons')
          .select(
            'id,code,title,description,discount_percentage,usage_count,usage_limit,is_active',
          )
          .eq('code', normalizedCode)
          .maybeSingle();

      if (currentRow == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon not found.')),
        );
        return;
      }

      final coupon = _CouponItem.fromJson(currentRow as Map<String, dynamic>);

      if (!coupon.isActive || coupon.usageCount >= coupon.usageLimit) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon is expired or disabled.')),
        );
        await _loadCoupons();
        return;
      }

      final updatedUsageCount = coupon.usageCount + 1;
      final shouldDisable = updatedUsageCount >= coupon.usageLimit;

      final dynamic updatedRow = await _supabase
          .from('coupons')
          .update({
            'usage_count': updatedUsageCount,
            'is_active': shouldDisable ? false : coupon.isActive,
          })
          .eq('id', coupon.id)
          .eq('usage_count', coupon.usageCount)
          .select(
            'id,code,title,description,discount_percentage,usage_count,usage_limit,is_active',
          )
          .maybeSingle();

      if (!mounted) return;

      if (updatedRow != null) {
        Navigator.of(context).pop(
          AppliedCouponResult(
            code: coupon.code,
            discountPercentage: coupon.discountPercentage,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon was just updated by another user. Try again.')),
        );
        await _loadCoupons();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong while applying coupon.')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _applyingCodes.remove(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width < 380 ? 14.0 : 20.0;
    final topGap = size.width < 380 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, topGap, horizontalPadding, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B4965), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Coupon',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Search coupon code',
                  hintStyle: const TextStyle(color: Color(0xFF9DB2CE), fontSize: 16),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4965)),
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCAE9FF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1B4965)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: _loadCoupons,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxContentWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
                            final visibleCoupons = _filteredCoupons();

                            return Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: maxContentWidth,
                                child: ListView(
                                  padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
                                  children: [
                                    const Text(
                                      'Available coupons',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (visibleCoupons.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'No coupons found.',
                                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                                        ),
                                      )
                                    else
                                      ...visibleCoupons.map(
                                        (coupon) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: _CouponCard(
                                            coupon: coupon,
                                            isApplying: _applyingCodes.contains(coupon.code),
                                            onApply: () => _applyCoupon(coupon.code),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  List<_CouponItem> _filteredCoupons() {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) return _coupons;

    return _coupons
        .where(
          (item) =>
              item.code.toUpperCase().contains(query) ||
              item.title.toUpperCase().contains(query),
        )
        .toList(growable: false);
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.isApplying,
    required this.onApply,
  });

  final _CouponItem coupon;
  final bool isApplying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final isExhausted = coupon.remainingUses <= 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  coupon.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discount: ${coupon.discountPercentage}% • Usage: ${coupon.usageCount}/${coupon.usageLimit}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 98,
            height: 44,
            child: OutlinedButton(
              onPressed: isExhausted || isApplying ? null : onApply,
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    isExhausted
                        ? Colors.transparent
                        : const Color(0xFF1B4965),
                side: BorderSide(
                  color:
                      isExhausted
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF1B4965),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  isApplying
                      ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        isExhausted ? 'Expired' : 'Apply',
                        style: TextStyle(
                          color:
                              isExhausted
                                  ? const Color(0xFF6B7280)
                                  : Colors.white,
                          fontSize: 14,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponItem {
  _CouponItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountPercentage,
    required this.usageCount,
    required this.usageLimit,
    required this.remainingUses,
    required this.isActive,
  });

  factory _CouponItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return _CouponItem(
      id: toInt(json['id']),
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountPercentage: toInt(json['discount_percentage']),
      usageCount: toInt(json['usage_count']),
      usageLimit: toInt(json['usage_limit']),
      remainingUses:
          json['remaining_uses'] == null
              ? (toInt(json['usage_limit']) - toInt(json['usage_count'])).clamp(0, 999999)
              : toInt(json['remaining_uses']),
      isActive: json['is_active'] == true,
    );
  }

  final int id;
  final String code;
  final String title;
  final String description;
  final int discountPercentage;
  final int usageCount;
  final int usageLimit;
  final int remainingUses;
  final bool isActive;
}
