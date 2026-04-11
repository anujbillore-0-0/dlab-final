import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/services/wishlist_service.dart';
import '../../../home/presentation/screens/dlabs_home_page.dart';
import '../../../home/presentation/screens/product_details_page.dart';

enum WishlistSort { relevance, priceLowToHigh, priceHighToLow, name }

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  static const Color _primary = Color(0xFF1B4965);
  static const String _imgProxyBase = 'http://app.dezign-lab.com:3000';

  final WishlistService _wishlistService = WishlistService.instance;

  List<WishlistProduct> _items = const <WishlistProduct>[];
  bool _loading = true;
  WishlistSort _sort = WishlistSort.relevance;
  bool _isEditMode = false;
  final Set<int> _selectedProductIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _wishlistService.initialize();
    final items = await _wishlistService.getAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _selectedProductIds.retainWhere(
        (id) => items.any((product) => product.id == id),
      );
      _loading = false;
    });
  }

  Future<void> _removeItem(int productId) async {
    await _wishlistService.remove(productId);
    _selectedProductIds.remove(productId);
    await _load();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedProductIds.clear();
      }
    });
  }

  void _toggleSelection(int productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _toggleSelectAll(List<WishlistProduct> items) {
    if (items.isEmpty) {
      return;
    }

    setState(() {
      final allIds = items.map((item) => item.id).toSet();
      final isAllSelected =
          _selectedProductIds.length == allIds.length &&
          _selectedProductIds.containsAll(allIds);

      if (isAllSelected) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedProductIds.isEmpty) {
      return;
    }

    final selected = _selectedProductIds.toList();
    for (final id in selected) {
      await _wishlistService.remove(id);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedProductIds.clear();
    });
    await _load();
  }

  List<WishlistProduct> get _sortedItems {
    final copied = _items.toList();
    switch (_sort) {
      case WishlistSort.relevance:
        copied.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case WishlistSort.priceLowToHigh:
        copied.sort((a, b) => _displayPrice(a).compareTo(_displayPrice(b)));
      case WishlistSort.priceHighToLow:
        copied.sort((a, b) => _displayPrice(b).compareTo(_displayPrice(a)));
      case WishlistSort.name:
        copied.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return copied;
  }

  double _displayPrice(WishlistProduct item) {
    final sale = item.salePrice;
    if (sale != null && sale > 0 && sale < item.regularPrice) {
      return sale;
    }
    return item.regularPrice;
  }

  int _priceDrops() {
    return _items
        .where((item) => item.salePrice != null && item.salePrice! < item.regularPrice)
        .length;
  }

  String _imgUrl(String url) {
    if (!kIsWeb) {
      return url;
    }
    return '$_imgProxyBase/api/image-proxy?url=${Uri.encodeComponent(url)}';
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = _sortedItems;
    final allSortedIds = sortedItems.map((item) => item.id).toSet();
    final isAllSelected =
        allSortedIds.isNotEmpty &&
        _selectedProductIds.length == allSortedIds.length &&
        _selectedProductIds.containsAll(allSortedIds);
    final totalValue = sortedItems.fold<double>(
      0,
      (sum, item) => sum + _displayPrice(item),
    );
    final selectedCountLabel = _selectedProductIds.length
        .toString()
        .padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: _primary),
        ),
        title: const Text(
          'Wishlist',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          _buildHeaderIcon(Icons.share_outlined),
          const SizedBox(width: 10),
          _buildHeaderIcon(
            _isEditMode ? Icons.close_rounded : Icons.edit_outlined,
            onTap: _toggleEditMode,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(
                      itemTotal: sortedItems.length,
                      totalValue: totalValue,
                      priceDrops: _priceDrops(),
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x1A62B6CB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => _toggleSelectAll(sortedItems),
                              child: Row(
                                children: [
                                  Icon(
                                    isAllSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: _primary,
                                    size: 25,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Select All',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _deleteSelected,
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x33FF0000),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Color(0xFFFF0000),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Delete($selectedCountLabel)',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Color(0xFFFF0000),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'All Items',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            height: 1.2,
                            color: Colors.black,
                          ),
                        ),
                        PopupMenuButton<WishlistSort>(
                          onSelected: (value) {
                            setState(() {
                              _sort = value;
                            });
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: WishlistSort.relevance,
                              child: Text('Relevance'),
                            ),
                            PopupMenuItem(
                              value: WishlistSort.priceLowToHigh,
                              child: Text('Price: Low to High'),
                            ),
                            PopupMenuItem(
                              value: WishlistSort.priceHighToLow,
                              child: Text('Price: High to Low'),
                            ),
                            PopupMenuItem(
                              value: WishlistSort.name,
                              child: Text('Name'),
                            ),
                          ],
                          child: Row(
                            children: const [
                              Text(
                                'Sort',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (sortedItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No liked products yet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width >= 1100
                              ? 4
                              : width >= 850
                                  ? 3
                                  : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedItems.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 252,
                            ),
                            itemBuilder: (context, index) {
                              final item = sortedItems[index];
                              return _WishlistCard(
                                item: item,
                                imageUrlBuilder: _imgUrl,
                                isEditMode: _isEditMode,
                                isSelected: _selectedProductIds.contains(item.id),
                                onSelectToggle: () => _toggleSelection(item.id),
                                onUnlike: () => _removeItem(item.id),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required int itemTotal,
    required double totalValue,
    required int priceDrops,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF6B7280), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Wishlist Summary',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Color(0xFF1B4965),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDADADA)),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildSummaryRow('Item Total', '$itemTotal'),
                _buildSummaryRow('Total Value', '\$${totalValue.toStringAsFixed(0)}'),
                _buildSummaryRow('Price Drops', '$priceDrops'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4965),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Move to Bag',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0B1527),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1B4965),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCAE9FF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1B4965)),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.item,
    required this.imageUrlBuilder,
    required this.isEditMode,
    required this.isSelected,
    required this.onSelectToggle,
    required this.onUnlike,
  });

  final WishlistProduct item;
  final String Function(String url) imageUrlBuilder;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onSelectToggle;
  final VoidCallback onUnlike;

  static const Color _primary = Color(0xFF1B4965);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _orange = Color(0xFFFF5500);
  static const Color _cardBorder = Color(0xFFF2F2F2);

  String _fmt(double price) => '\$${price.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final hasSale = item.salePrice != null && item.salePrice! < item.regularPrice;
    final displayPrice = hasSale ? item.salePrice! : item.regularPrice;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isEditMode) {
          onSelectToggle();
          return;
        }
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              product: ProductModel(
                id: item.id,
                name: item.name,
                images: item.images,
                imageUrl: item.imageUrl,
                salePrice: item.salePrice,
                regularPrice: item.regularPrice,
                categoryId: item.categoryId,
                shortDescription: item.shortDescription,
                description: item.description,
                isVariable: item.isVariable,
                length: item.length,
                width: item.width,
                height: item.height,
              ),
              sourceTabIndex: 0,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : _cardBorder,
            width: isSelected ? 1.2 : 1,
          ),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            else
              const BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 9,
                spreadRadius: 0,
              ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: item.imageUrl != null
                      ? Image.network(
                          imageUrlBuilder(item.imageUrl!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.devices_other_rounded,
                              size: 64,
                              color: Color(0xFFCAE9FF),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.devices_other_rounded,
                            size: 64,
                            color: Color(0xFFCAE9FF),
                          ),
                        ),
                ),
                Positioned(
                  left: 0,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          '4.5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.star_rounded, color: Colors.white, size: 10),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 8,
                  child: GestureDetector(
                    onTap: onUnlike,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0x19191919),
                        borderRadius: BorderRadius.circular(29),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          size: 16,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Text(
                _fmt(displayPrice),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1B4965), Color(0xFF2B729C)],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Text(
                          'Add to Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
