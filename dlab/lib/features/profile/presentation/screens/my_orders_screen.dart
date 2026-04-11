import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'track_order_screen.dart';

const _primaryColor = Color(0xFF1B4965);
const _borderBlue = Color(0xFFCAE9FF);
const _bgLight = Color(0xFFF9F9F9);
const _mutedText = Color(0xFF6B7280);

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  final _OrdersRepository _repository = _OrdersRepository();

  List<_OrderItem> _allOrders = const [];
  List<_OrderItem> _visibleOrders = const [];

  bool _isLoading = true;
  bool _isListening = false;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadOrders();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _repository.fetchOrdersForCurrentUser();
    if (!mounted) return;
    setState(() {
      _allOrders = orders;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered =
        _allOrders.where((order) {
          final matchesStatus =
              _statusFilter == 'All' || order.status == _statusFilter;
          if (!matchesStatus) return false;

          if (query.isEmpty) return true;

          final haystack =
              '${order.title} ${order.subtitle} ${order.status}'.toLowerCase();
          return haystack.contains(query);
        }).toList();

    if (!mounted) return;
    setState(() => _visibleOrders = filtered);
  }

  Future<void> _onVoiceTap() async {
    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      _showMessage('Stopped listening');
      return;
    }

    final isAvailable = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );

    if (!isAvailable) {
      _showMessage(
        'Voice recognition unavailable. Allow mic permission in Chrome site settings.',
      );
      return;
    }

    setState(() => _isListening = true);

    await _speechToText.listen(
      listenMode: stt.ListenMode.search,
      partialResults: true,
      onResult: (result) {
        final recognizedText = result.recognizedWords.trim();
        if (!mounted || recognizedText.isEmpty) return;

        _searchController.text = recognizedText;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );

        if (result.finalResult && mounted) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _showFilterSheet() async {
    const options = ['All', 'Delivered', 'Processing', 'Cancelled'];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      options.map((option) {
                        final selected = option == _statusFilter;
                        return ChoiceChip(
                          label: Text(option),
                          selected: selected,
                          onSelected: (_) => Navigator.of(context).pop(option),
                          selectedColor: const Color(0xFFCAE9FF),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _statusFilter = selected);
      _applyFilters();
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      'My Orders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _OrdersSearchBar(
                controller: _searchController,
                isListening: _isListening,
                onFilterTap: _showFilterSheet,
                onVoiceTap: _onVoiceTap,
                onScanTap:
                    () =>
                        _showMessage('Barcode scanner for orders coming soon'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFDADADA), thickness: 0.5),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _visibleOrders.isEmpty
                      ? RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No orders yet',
                                style: TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Center(
                              child: Text(
                                'Orders from Supabase will appear here.',
                                style: TextStyle(
                                  color: _mutedText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          itemCount: _visibleOrders.length,
                          separatorBuilder:
                              (_, __) => const Divider(
                                height: 24,
                                thickness: 0.5,
                                color: Color(0xFFDADADA),
                              ),
                          itemBuilder: (_, index) {
                            final order = _visibleOrders[index];
                            return _OrderTile(
                              order: order,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => TrackOrderScreen(
                                          orderId: order.id,
                                          productTitle: order.title,
                                          imageUrl: order.imageUrl,
                                          deliveredOnLabel:
                                              order.deliveredOnLabel,
                                        ),
                                  ),
                                );
                              },
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
}

class _OrdersSearchBar extends StatelessWidget {
  const _OrdersSearchBar({
    required this.controller,
    required this.isListening,
    required this.onFilterTap,
    required this.onVoiceTap,
    required this.onScanTap,
  });

  final TextEditingController controller;
  final bool isListening;
  final VoidCallback onFilterTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderBlue),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.tune_rounded,
                color: Color(0xFFFF5500),
                size: 25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 34, color: const Color(0xFF9DB2CE)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Color(0xFF9DB2CE), fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
          _ActionCircle(
            onTap: onVoiceTap,
            child: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: const Color(0xFFFF5500),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          _ActionCircle(
            onTap: onScanTap,
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFFFF5500),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21.5),
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          border: Border.all(color: _borderBlue),
          borderRadius: BorderRadius.circular(21.5),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final _OrderItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 91,
                height: 91,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFF3F4F6),
                  image:
                      order.imageUrl != null && order.imageUrl!.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(order.imageUrl!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    order.imageUrl == null || order.imageUrl!.isEmpty
                        ? const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF9CA3AF),
                          size: 34,
                        )
                        : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.deliveredOnLabel,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        6,
                        (index) => const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.star_rounded,
                            size: 24,
                            color: Color(0xFFE6E6E6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rate this product now',
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _mutedText,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _fallbackOrderItems = [
  _OrderItem(
    id: 'CD2454351236561223',
    title: 'Apple MacBook Pro Core i9 9th Gen -',
    subtitle: 'Rate this product now',
    deliveredOnLabel: 'Delivered on Dec 09, 2025',
    status: 'Delivered',
  ),
];

class _OrderItem {
  const _OrderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.deliveredOnLabel,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String deliveredOnLabel;
  final String status;
  final String? imageUrl;

  factory _OrderItem.fromMap(Map<String, dynamic> map) {
    final rawDate =
        (map['delivered_on'] ?? map['created_at'] ?? '').toString().trim();

    return _OrderItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? map['product_name'] ?? 'Order item').toString(),
      subtitle: (map['subtitle'] ?? map['description'] ?? '').toString(),
      deliveredOnLabel: _formatDeliveredOn(rawDate),
      status: (map['status'] ?? 'Delivered').toString(),
      imageUrl: map['image_url']?.toString(),
    );
  }

  static String _formatDeliveredOn(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'Delivered';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[parsed.month - 1];
    final day = parsed.day.toString().padLeft(2, '0');
    return 'Delivered on $month $day, ${parsed.year}';
  }
}

class _OrdersRepository {
  Future<List<_OrderItem>> fetchOrdersForCurrentUser() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return _fallbackOrderItems;

    try {
      // Future-ready: once your `orders` table exists in Supabase,
      // keep/extend this query and mapping.
      final rows = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      if (rows is! List) return _fallbackOrderItems;

      final mapped =
          rows
              .whereType<Map<String, dynamic>>()
              .map(_OrderItem.fromMap)
              .toList();

      if (mapped.isEmpty) return _fallbackOrderItems;

      return mapped;
    } catch (_) {
      // Table/column may not exist yet; return empty until backend is ready.
      return _fallbackOrderItems;
    }
  }
}
