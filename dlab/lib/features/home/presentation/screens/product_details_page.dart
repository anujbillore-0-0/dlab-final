import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/banner_config_service.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../notifications/presentation/screens/notifications_page.dart';
import 'dlabs_home_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT DETAILS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;
  final int sourceTabIndex;
  const ProductDetailsPage({
    super.key,
    required this.product,
    this.sourceTabIndex = 0,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  // ── Design tokens ─────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1B4965);
  static const Color _secondary = Color(0xFF62B6CB);
  static const Color _orange = Color(0xFFFF5500);

  static const String _imgProxyBase = 'http://app.dezign-lab.com:3000';

  // ── Controllers ───────────────────────────────────────────────────────────
  late final PageController _pageController;
  final ScrollController _scrollController = ScrollController();
  int _currentImagePage = 0;

  // ── Full product (for Length/Width/Height) ────────────────────────────────
  ProductModel? _fullProduct;

  // ── Variants ──────────────────────────────────────────────────────────────
  List<VariantModel> _variants = [];
  VariantModel? _selectedVariant;
  bool _loadingVariants = true;

  // ── Description expand ────────────────────────────────────────────────────
  bool _descExpanded = false;

  // ── Review UI state ───────────────────────────────────────────────────────
  String _activeReviewFilter = 'All';
  int _activeSortPage = 1;

  // ── Color selector ────────────────────────────────────────────────────────
  int _selectedColorIndex = 0;

  // ── Fake MRP (stable per product) ────────────────────────────────────────
  late final int _fakeMrp;

  // ── Related products ─────────────────────────────────────────────────────
  late final Future<List<ProductModel>> _relatedFuture;

  // ── Infinite scroll (after ad banner) ────────────────────────────────────
  final List<ProductModel> _moreProducts = [];
  bool _loadingMore = false;
  bool _hasMore = true;
  int _moreOffset = 20;
  String? _promo2BannerUrl;
  String _deliveryCity = 'USA';
  String _deliveryCountry = 'United States';
  static const int _pageSize = 10;

  // ── Helpers ───────────────────────────────────────────────────────────────
  final WishlistService _wishlistService = WishlistService.instance;
  final CartService _cartService = CartService.instance;

  List<String> get _displayImages {
    if (_selectedVariant != null && _selectedVariant!.images.isNotEmpty) {
      return _selectedVariant!.images;
    }
    return widget.product.images.isNotEmpty ? widget.product.images : [];
  }

  double get _displayPrice {
    if (_selectedVariant != null) {
      return _selectedVariant!.salePrice ??
          _selectedVariant!.regularPrice ??
          widget.product.regularPrice;
    }
    return widget.product.salePrice ?? widget.product.regularPrice;
  }

  String? _safeField(String key) {
    final p = _fullProduct ?? widget.product;
    String? v;
    if (key == 'weight')
      v = p.weight;
    else if (key == 'length')
      v = p.length;
    else if (key == 'width')
      v = p.width;
    else if (key == 'height')
      v = p.height;
    final t = v?.trim() ?? '';
    return t.isNotEmpty ? t : null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _wishlistService.initialize();
    _cartService.initialize();
    _loadPromo2Banner();
    _pageController = PageController();
    final rng = Random(widget.product.id);
    _fakeMrp = _displayPrice.round() + 200 + rng.nextInt(201);
    _relatedFuture = ProductService.fetchProducts(limit: 4, offset: 10);

    ProductService.fetchProductById(widget.product.id).then((p) {
      if (mounted && p != null) setState(() => _fullProduct = p);
    });

    if (widget.product.isVariable) {
      ProductService.fetchVariants(widget.product.id).then((v) {
        if (mounted) {
          setState(() {
            _variants = v;
            _loadingVariants = false;
          });
        }
      });
    } else {
      _loadingVariants = false;
    }

    _scrollController.addListener(_onScroll);
    _loadMore();
    _loadSavedLocation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore) return;
    final threshold = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= threshold) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final products = await ProductService.fetchProducts(
      limit: _pageSize,
      offset: _moreOffset,
    );
    if (!mounted) return;
    setState(() {
      _moreProducts.addAll(products);
      _moreOffset += products.length;
      _loadingMore = false;
      if (products.length < _pageSize) _hasMore = false;
    });
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('saved_city');
    final country = prefs.getString('saved_country');
    if (city != null && country != null && city.isNotEmpty) {
      if (mounted) {
        setState(() {
          _deliveryCity = city;
          _deliveryCountry = country;
        });
      }
    }
  }

  Future<void> _loadPromo2Banner() async {
    final urls = await BannerConfigService.instance.getBannerUrls('promo2');
    if (!mounted) return;
    setState(() {
      _promo2BannerUrl = (urls != null && urls.isNotEmpty) ? urls.first : null;
    });
  }

  Future<void> _addCurrentProductToCart() async {
    final images = _displayImages;
    await _cartService.addOrIncrement(
      CartProduct(
        id: widget.product.id,
        name: widget.product.name,
        images: images,
        imageUrl: images.isNotEmpty ? images.first : widget.product.imageUrl,
        salePrice: widget.product.salePrice,
        regularPrice: _displayPrice,
        quantity: 1,
        addedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _saveLocation(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_city', city);
    await prefs.setString('saved_country', country);
  }

  String _imgUrl(String url) =>
      kIsWeb
          ? '$_imgProxyBase/api/image-proxy?url=${Uri.encodeComponent(url)}'
          : url;

  String _fmt(double price) => '\$${price.toStringAsFixed(0)}';

  Future<void> _toggleWishlist() async {
    await _wishlistService.toggle(
      WishlistProduct(
        id: widget.product.id,
        name: widget.product.name,
        images: widget.product.images,
        imageUrl: widget.product.imageUrl,
        salePrice: widget.product.salePrice,
        regularPrice: widget.product.regularPrice,
        categoryId: widget.product.categoryId,
        shortDescription: widget.product.shortDescription,
        description: widget.product.description,
        isVariable: widget.product.isVariable,
        length: widget.product.length,
        width: widget.product.width,
        height: widget.product.height,
        addedAt: DateTime.now(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image slider ──────────────────────────────────────
                  _buildImageSlider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductHeader(),
                        const SizedBox(height: 20),
                        _buildColorAndPrice(),
                        const SizedBox(height: 10),
                        _buildFreeDelivery(),
                        const SizedBox(height: 20),
                        // ── Description + expandable long desc ───────────
                        _buildDescriptionSection(),
                        // ── Specs: Length/Width/Height ────────────────────
                        _buildSpecsTable(),
                        const SizedBox(height: 16),
                        _buildDeliverToBanner(),
                        const SizedBox(height: 20),
                        _buildDeliveryBadges(),
                        const SizedBox(height: 24),
                        // ── Product Reviews ────────────────────────────────
                        _buildProductReviews(),
                        const SizedBox(height: 20),
                        // ── You may also like ──────────────────────────────
                        _buildRelatedProducts(),
                        const SizedBox(height: 20),
                        // ── AD Banner ──────────────────────────────────────
                        _buildAdBanner(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  // ── Infinite scroll products after banner ─────────────
                  _buildMoreProductsSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _buildStickyButtons(),
        ],
      ),
      bottomNavigationBar: const _PdpBottomNav(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR  ·  Frame 2123
  // ─────────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: _primary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Details',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCAE9FF)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: _primary,
              size: 22,
            ),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsPage(),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE SLIDER  ·  Rectangle 381
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildImageSlider() {
    final images = _displayImages;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 350,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFDEDEDE),
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFE1E1E1)),
            ),
          ),
          child:
              images.isEmpty
                  ? const Center(
                    child: Icon(
                      Icons.devices_other_rounded,
                      size: 160,
                      color: Color(0xFFCAE9FF),
                    ),
                  )
                  : PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImagePage = i),
                    itemBuilder:
                        (_, i) => Image.network(
                          _imgUrl(images[i]),
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.devices_other_rounded,
                                  size: 160,
                                  color: Color(0xFFCAE9FF),
                                ),
                              ),
                        ),
                  ),
        ),
        // Wishlist — Group 38/39: 30×30, rgba(25,25,25,0.1)
        Positioned(
          right: 16,
          top: 16,
          child: ValueListenableBuilder<Set<int>>(
            valueListenable: _wishlistService.likedIds,
            builder: (context, likedIds, _) {
              final isLiked = likedIds.contains(widget.product.id);
              return InkWell(
                onTap: _toggleWishlist,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0x1A191919),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                    size: 16,
                    color: isLiked ? _primary : Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
        // Dots: 15px inactive / 27px active
        if (images.length > 1)
          Positioned(
            bottom: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(images.length, (i) {
                final active = i == _currentImagePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: active ? 27 : 15,
                  decoration: BoxDecoration(
                    color:
                        active ? Colors.black : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(31),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCT HEADER  ·  Frame 2126 + 2125
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDD4A00),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '4.5',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.star_rounded, color: Colors.white, size: 12),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '(90 Reviews)',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF6B7280),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            const Text(
              'Only 5 left in stock',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFFFF383C),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COLOR + PRICE ROW  ·  Frame 2166
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildColorAndPrice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _loadingVariants
            ? const SizedBox(
              height: 62,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
            : _variants.isNotEmpty
            ? _buildVariantSelector()
            : _buildColorCircles(),
        _buildPriceBlock(),
      ],
    );
  }

  Widget _buildColorCircles() {
    const colorValues = [
      Color(0xFF000000),
      Color(0xFFC0C0C0),
      Color(0xFFFF0000),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose color',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF303030),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(colorValues.length, (i) {
            final sel = i == _selectedColorIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedColorIndex = i),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 30.8,
                height: 30.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorValues[i],
                  border: Border.all(
                    color: sel ? _secondary : const Color(0xFFDDDDDD),
                    width: sel ? 2 : 1.03,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildVariantSelector() {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose variant',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF303030),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _variants.map((v) {
                  final sel = _selectedVariant?.id == v.id;
                  return GestureDetector(
                    onTap:
                        () => setState(() {
                          _selectedVariant = sel ? null : v;
                          _currentImagePage = 0;
                          _pageController.jumpToPage(0);
                        }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? _primary : Colors.white,
                        border: Border.all(
                          color: sel ? _primary : const Color(0xFFDDDDDD),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        v.variantName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: sel ? Colors.white : const Color(0xFF111827),
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBlock() {
    final price = _displayPrice;
    final saveAmt = _fakeMrp - price.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _fmt(price),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fmt(_fakeMrp.toDouble()),
              style: const TextStyle(
                fontFamily: 'Inter',
                decoration: TextDecoration.lineThrough,
                color: Color(0xFF757575),
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Save \$$saveAmt',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFFFF383C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FREE DELIVERY ROW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFreeDelivery() {
    return Row(
      children: const [
        Icon(Icons.check_circle_rounded, color: Color(0xFF26A541), size: 16),
        SizedBox(width: 8),
        Text(
          'Free Delivery by Tomorrow',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF26A541),
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DESCRIPTION  ·  Frame 2170
  //   Short description shown as body text.
  //   "Details" row at bottom expands to show full long description.
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDescriptionSection() {
    final shortRaw = widget.product.shortDescription;
    final longRaw = (_fullProduct ?? widget.product).description;

    final shortCleaned = shortRaw != null ? _cleanText(shortRaw) : '';
    final longCleaned = longRaw != null ? _cleanText(longRaw) : '';

    if (shortCleaned.isEmpty && longCleaned.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Description" heading — Inter 600 24px #1B4965
        const Text(
          'Description',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _primary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),

        // Short description body — Inter 400 16px #374151
        if (shortCleaned.isNotEmpty)
          Text(
            shortCleaned,
            maxLines: _descExpanded ? null : 2,
            overflow:
                _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF374151),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),

        // Expandable long description
        if (longCleaned.isNotEmpty) ...[
          const SizedBox(height: 8),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                _descExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                _descExpanded ? longCleaned : '',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF374151),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          // "Details" toggle row — Inter 400 16px #1B4965 + chevron
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _descExpanded ? 'Show less' : 'Details',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: _primary,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _descExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SPECS TABLE  ·  Frame 2169
  //   Weight / Length / Width / Height rows with 0.5px #6B7280 dividers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSpecsTable() {
    final specs = <_SpecRow>[
      _SpecRow('Weight', _safeField('weight') ?? '-'),
      _SpecRow('Length', _safeField('length') ?? '-'),
      _SpecRow('Width', _safeField('width') ?? '-'),
      _SpecRow('Height', _safeField('height') ?? '-'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(
          specs.length,
          (i) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      specs[i].label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Color(0xFF757575),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      specs[i].value,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Color(0xFF757575),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELIVER TO BANNER  ·  Frame 2132
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDeliverToBanner() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (ctx) => LocationPickerSheet(
                initialCity: _deliveryCity,
                initialCountry: _deliveryCountry,
                onApply: (city, state, country) {
                  setState(() {
                    _deliveryCity = city;
                    _deliveryCountry = country;
                  });
                  _saveLocation(city, country);
                },
              ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF8FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Deliver to $_deliveryCity, $_deliveryCountry  —  Change',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF303030),
                  height: 1.375,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: _primary.withValues(alpha: 0.6),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELIVERY BADGES  ·  Frame 2165
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDeliveryBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _DeliveryBadge(
          icon: Icons.local_shipping_outlined,
          label: 'Free Shipping',
        ),
        _DeliveryBadge(icon: Icons.replay_outlined, label: 'Easy Returns'),
        _DeliveryBadge(
          icon: Icons.verified_user_outlined,
          label: '1 Year Warranty',
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCT REVIEWS  ·  Frame 505 + Frame 508
  //
  // CSS spec:
  //   Frame 505 = "Product Reviews" heading + dashed-border summary box
  //     Summary box (388×253, border: 0.8px dashed #DADADA, radius 4):
  //       Frame 474 (top): orange circle "4.7" | stars 5× | "90 Reviews"
  //       Frame 478 (below, left:15 top:104): 5 rating bar rows
  //         Each row: star-number (12px) + star-icon (16px) |
  //                   bg bar (#E4E9EE 8px) + fill (#1B4965) | count text
  //   Frame 508 = "Review Lists" heading + filter tabs + pagination + testimonials
  //     Filter tabs (Frame 481/482):
  //       Active: #EBEBEB bg + #333333 border 1px
  //       Inactive: transparent + #E4E9EE border 1px
  //     Pagination (Frame 202):
  //       Boxes 48.5×50.25, radius 8
  //       Active: white bg + #FF5500 border + #1B4965 text
  //       Inactive: transparent + #E4E9EE border + #757575 text
  //       Arrow box: #E4E9EE border
  //     Testimonial (Frame 507):
  //       Stars (Frame 178) → Title + date (Frame 167) → User + like/dislike
  //       Line 14/15: 1px solid #E4E9EE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductReviews() {
    const bars = [
      (5, 0.63, 57),
      (4, 0.21, 19),
      (3, 0.09, 8),
      (2, 0.04, 4),
      (1, 0.03, 3),
    ];
    final filters = ['All', 'Positive Reviews', 'Critical Reviews'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFF2F2F2), thickness: 1),
        const SizedBox(height: 16),

        const Text(
          'Product Reviews',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF141414),
            letterSpacing: -0.2,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        _DashedBorderBox(
          color: const Color(0xFFDADADA),
          strokeWidth: 0.8,
          radius: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: ring + stars + review text ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Donut/ring circle showing 4.5
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CustomPaint(
                        painter: _RatingRingPainter(
                          rating: 4.5,
                          maxRating: 5.0,
                          bgColor: const Color(0xFFE4E9EE),
                          fillColor: const Color(0xFFFFA439),
                          strokeWidth: 7,
                        ),
                        child: const Center(
                          child: Text(
                            '4.5',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF0B0F0E),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Stars + review count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => const Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: Color(0xFFFFA439),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'from 90 reviews',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0B0F0E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Rating bars 5.0 → 1.0 ──
                ...bars.map((e) {
                  final star = e.$1;
                  final ratio = e.$2;
                  final count = e.$3;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Star label e.g. "5.0 ★"
                        SizedBox(
                          width: 14,
                          child: Text(
                            '$star',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF0B0F0E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const Text(
                          '.0',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF0B0F0E),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFA439),
                        ),
                        const SizedBox(width: 8),
                        // Progress bar
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE4E9EE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF0B0F0E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Review Lists',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF141414),
            letterSpacing: -0.2,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                filters.map((f) {
                  final active = f == _activeReviewFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _activeReviewFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? const Color(0xFFEBEBEB)
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              active
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFE4E9EE),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight:
                              active ? FontWeight.w500 : FontWeight.w400,
                          color:
                              active
                                  ? const Color(0xFF141414)
                                  : const Color(0xFF0B0F0E),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 32),

        _buildTestimonial(
          stars: 5,
          reviewTitle: 'This is amazing product I have.',
          date: 'Nov 23, 2023',
          userName: 'John D.',
          likeCount: 128,
        ),
        const SizedBox(height: 16),
        _buildTestimonial(
          stars: 4,
          reviewTitle: 'Great quality, fast delivery!',
          date: 'Dec 10, 2023',
          userName: 'Sarah M.',
          likeCount: 94,
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Row(
            children: [
              ...List.generate(4, (i) {
                final page = i + 1;
                final active = page == _activeSortPage;
                return GestureDetector(
                  onTap: () => setState(() => _activeSortPage = page),
                  child: Container(
                    margin: const EdgeInsets.only(right: 9),
                    width: 48,
                    height: 50,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: active ? _orange : const Color(0xFFE4E9EE),
                        width: 1.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$page',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: active ? _primary : const Color(0xFF757575),
                      ),
                    ),
                  ),
                );
              }),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE4E9EE)),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: -1.5708,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF141414),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // Single testimonial — Frame 507 child
  Widget _buildTestimonial({
    required int stars,
    required String reviewTitle,
    required String date,
    required String userName,
    required int likeCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frame 178: stars row
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              Icons.star_rounded,
              size: 20,
              color: i < stars ? const Color(0xFFFFA439) : Colors.grey.shade300,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Frame 167: title + date
        Text(
          reviewTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF141414),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B7280),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        // User row — Frame 194 + Frame 484
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Frame 194: avatar + username
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _secondary,
                  child: Text(
                    userName.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0B0F0E),
                    height: 1.6,
                  ),
                ),
              ],
            ),
            // Frame 484: like box + dislike box
            Row(
              children: [
                // Like — green thumb + count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE4E9EE),
                      width: 1.19,
                    ),
                    borderRadius: BorderRadius.circular(7.16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.thumb_up_outlined,
                        size: 20,
                        color: Color(0xFF1D9E34),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$likeCount',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0B0F0E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Dislike — flipped thumb (matrix: scaleY -1)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE4E9EE),
                      width: 1.15,
                    ),
                    borderRadius: BorderRadius.circular(6.88),
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      1,
                      -1,
                      1,
                    ), // CSS matrix(1,0,0,-1,0,0)
                    child: const Icon(
                      Icons.thumb_up_outlined,
                      size: 20,
                      color: Color(0xFF0B0F0E),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Line 14/15: 1px solid #E4E9EE
        const Divider(height: 1, thickness: 1, color: Color(0xFFE4E9EE)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YOU MAY ALSO LIKE  ·  Frame 2059
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRelatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFF2F2F2), thickness: 1),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'You May Also Like',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFFFF5500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<ProductModel>>(
          future: _relatedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final products =
                (snapshot.data ?? [])
                    .where((p) => p.id != widget.product.id)
                    .take(4)
                    .toList();
            if (products.isEmpty) return const SizedBox.shrink();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 11,
                mainAxisSpacing: 11,
                childAspectRatio: 0.56,
              ),
              itemCount: products.length,
              itemBuilder:
                  (_, i) => _RelatedCard(product: products[i], imgUrl: _imgUrl),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AD BANNER  ·  CSS "AD22-11" — #FDCC3A, decorative circles, 388×142
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAdBanner() {
    if (_promo2BannerUrl != null) {
      return GestureDetector(
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => const QuickTypeProductsPage(
                      title: 'Hot Deals',
                      typeKey: 'banner',
                    ),
              ),
            ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: double.infinity,
            height: 142,
            child: Image.network(
              _promo2BannerUrl!,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Image.asset('assets/promo.png', fit: BoxFit.contain),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => const QuickTypeProductsPage(
                    title: 'Hot Deals',
                    typeKey: 'banner',
                  ),
            ),
          ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: double.infinity,
          height: 142,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Container(color: const Color(0xFFFDCC3A)),
            Positioned(
              right: -40,
              top: -44,
              child: Container(
                width: 246,
                height: 246,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE4F5FF),
                ),
              ),
            ),
            Positioned(
              right: -16,
              top: -20,
              child: Container(
                width: 198,
                height: 198,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFCDEEFF),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 4,
              child: Container(
                width: 151,
                height: 151,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: -4,
              top: 8,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFED6D6),
                ),
              ),
            ),
            Positioned(
              left: 158,
              top: 25,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFAAFEFE),
                ),
              ),
            ),
            Positioned(
              left: 188,
              top: 118,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFEBB8),
                ),
              ),
            ),
            const Positioned(
              left: 22,
              top: 10,
              child: SizedBox(
                width: 174,
                child: Text(
                  'Buy all the Items at best price range',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Color(0xFF020909),
                    height: 1.2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 92,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF27C4F4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Shop Now',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 50,
              top: 127,
              child: Text(
                'T&C Apply',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: Color(0xFF134795),
                  letterSpacing: 0.05,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INFINITE SCROLL PRODUCTS SECTION
  //   Appears after ad banner, same grid as home page infinite section
  //   Loads 10 products at a time as user scrolls
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMoreProductsSection() {
    if (_moreProducts.isEmpty && !_loadingMore) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 50) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFFF2F2F2), thickness: 1),
          const SizedBox(height: 12),
          const Text(
            'More Products',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                _moreProducts
                    .map(
                      (p) => SizedBox(
                        width: cardWidth,
                        child: _ProductCard(product: p, imgUrl: _imgUrl),
                      ),
                    )
                    .toList(),
          ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STICKY CTA  ·  Group 84
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStickyButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addCurrentProductToCart,
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: _primary,
                size: 24,
              ),
              label: const Text(
                'Add to Cart',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: _primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 24,
              ),
              label: const Text(
                'Buy Now',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT CLEANER
  // ─────────────────────────────────────────────────────────────────────────
  String _cleanText(String raw) {
    var s = raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'&#\d+;'), '')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '')
        .replaceAll(RegExp(r'#\w+'), '')
        .replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2600}-\u{27BF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{FE00}-\u{FEFF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{200B}-\u{200D}]', unicode: true), '')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return s
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n')
        .trim();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHED BORDER BOX  ·  CustomPainter draws proper CSS-style dashed border
//   CSS: border: 0.8px dashed #DADADA; border-radius: 4px
// ─────────────────────────────────────────────────────────────────────────────
class _DashedBorderBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double radius;

  const _DashedBorderBox({
    required this.child,
    required this.color,
    this.strokeWidth = 0.8,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    const dashLen = 6.0;
    const gapLen = 4.0;
    final r = Radius.circular(radius);
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, r);
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final length = metrics.length;

    double dist = 0;
    while (dist < length) {
      final end = (dist + dashLen).clamp(0.0, length);
      canvas.drawPath(metrics.extractPath(dist, end), paint);
      dist += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}

class _RatingRingPainter extends CustomPainter {
  final double rating;
  final double maxRating;
  final Color bgColor;
  final Color fillColor;
  final double strokeWidth;

  const _RatingRingPainter({
    required this.rating,
    required this.maxRating,
    required this.bgColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5708; // -90 degrees, start from top

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      6.2832, // full circle
      false,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Fill arc based on rating
    final sweepAngle = (rating / maxRating) * 6.2832;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = fillColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RatingRingPainter old) =>
      old.rating != rating ||
      old.fillColor != fillColor ||
      old.bgColor != bgColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD  ·  same card used in home page (reused for "More Products")
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final String Function(String) imgUrl;

  const _ProductCard({required this.product, required this.imgUrl});

  String _fmt(double p) => '\$${p.toStringAsFixed(0)}';

  int _discountPct() {
    final sp = product.salePrice;
    if (sp == null || product.regularPrice == 0) return 0;
    return ((product.regularPrice - sp) / product.regularPrice * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final hasSale =
        product.salePrice != null && product.salePrice! < product.regularPrice;
    final displayPrice = hasSale ? product.salePrice! : product.regularPrice;
    final discount = _discountPct();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsPage(product: product),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF2F2F2)),
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 9, spreadRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 122,
                  width: double.infinity,
                  child:
                      product.imageUrl != null
                          ? Image.network(
                            imgUrl(product.imageUrl!),
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.devices_other_rounded,
                                    size: 72,
                                    color: Color(0xFFCAE9FF),
                                  ),
                                ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.devices_other_rounded,
                              size: 72,
                              color: Color(0xFFCAE9FF),
                            ),
                          ),
                ),
                Positioned(
                  left: 0,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5500),
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
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmt(displayPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  if (hasSale)
                    Row(
                      children: [
                        Text(
                          _fmt(product.regularPrice),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$discount% off',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1B4965), Color(0xFF2B729C)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFCAE9FF),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Add to Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV  ·  CSS Bottom Nav — identical to home page
//   #111827 bg · Home active (#62B6CB) · center circle #62B6CB
// ─────────────────────────────────────────────────────────────────────────────
class _PdpBottomNav extends StatelessWidget {
  const _PdpBottomNav();

  void _go(BuildContext ctx, int navIndex) {
    final pageIndex = navIndex > 2 ? navIndex - 1 : navIndex;
    Navigator.of(ctx, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainShell(initialIndex: pageIndex)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final barHeight = (w * 0.145).clamp(56.0, 72.0);
          final centerSize = (barHeight * 0.9).clamp(52.0, 68.0);
          final iconSize = (w * 0.06).clamp(22.0, 26.0);
          final labelSize = (w * 0.03).clamp(11.0, 13.0);

          return Container(
            height: barHeight,
            color: const Color(0xFF111827),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: barHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: _PdpNavItem(
                            navIndex: 0,
                            asset: 'assets/icons/home.png',
                            label: 'Home',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            active: true,
                            go: (i) => _go(context, i),
                          ),
                        ),
                        Expanded(
                          child: _PdpNavItem(
                            navIndex: 1,
                            asset: 'assets/icons/category.png',
                            label: 'Categories',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            active: false,
                            go: (i) => _go(context, i),
                          ),
                        ),
                        SizedBox(width: centerSize * 0.7),
                        Expanded(
                          child: _PdpNavItem(
                            navIndex: 3,
                            asset: 'assets/icons/cart.png',
                            label: 'Cart',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            active: false,
                            go: (i) => _go(context, i),
                          ),
                        ),
                        Expanded(
                          child: _PdpNavItem(
                            navIndex: 4,
                            asset: 'assets/icons/user.png',
                            label: 'Profile',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            active: false,
                            go: (i) => _go(context, i),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: barHeight - (centerSize * 0.75),
                  child: GestureDetector(
                    onTap: () => _go(context, 2),
                    child: Container(
                      width: centerSize,
                      height: centerSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF62B6CB),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF111827),
                          width: centerSize * 0.08,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/center.png',
                          width: iconSize,
                          height: iconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PdpNavItem extends StatelessWidget {
  final int navIndex;
  final String asset;
  final String label;
  final double iconSize;
  final double labelSize;
  final bool active;
  final ValueChanged<int> go;

  const _PdpNavItem({
    required this.navIndex,
    required this.asset,
    required this.label,
    required this.iconSize,
    required this.labelSize,
    required this.active,
    required this.go,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF62B6CB) : const Color(0xFF676D75);
    return GestureDetector(
      onTap: () => go(navIndex),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(asset, width: iconSize, height: iconSize, color: color),
          SizedBox(height: labelSize * 0.4),
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              color: color,
              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _DeliveryBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DeliveryBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFF5500), size: 24),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFFFF5500),
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RELATED CARD  ·  Frame 2020/2022 — gradient "Add to Cart" button
// ─────────────────────────────────────────────────────────────────────────────
class _RelatedCard extends StatelessWidget {
  final ProductModel product;
  final String Function(String) imgUrl;
  final CartService _cartService = CartService.instance;
  _RelatedCard({required this.product, required this.imgUrl});

  String _fmt(double p) => '\$${p.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final hasSale =
        product.salePrice != null && product.salePrice! < product.regularPrice;
    final displayPrice = hasSale ? product.salePrice! : product.regularPrice;

    return GestureDetector(
      onTap:
          () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsPage(product: product),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF2F2F2)),
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 9, spreadRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child:
                        product.imageUrl != null
                            ? Image.network(
                              imgUrl(product.imageUrl!),
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.devices_other_rounded,
                                      size: 50,
                                      color: Color(0xFFCAE9FF),
                                    ),
                                  ),
                            )
                            : const Center(
                              child: Icon(
                                Icons.devices_other_rounded,
                                size: 50,
                                color: Color(0xFFCAE9FF),
                              ),
                            ),
                  ),
                  Positioned(
                    left: 3,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5500),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '4.5',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _fmt(displayPrice),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            if (hasSale)
              Text(
                _fmt(product.regularPrice),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF757575),
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w400,
                ),
              ),
            const SizedBox(height: 10),
            ValueListenableBuilder<Map<int, int>>(
              valueListenable: _cartService.quantities,
              builder: (context, quantities, _) {
                final qty = quantities[product.id] ?? 0;
                if (qty <= 0) {
                  return GestureDetector(
                    onTap: () async {
                      await _cartService.addOrIncrement(
                        CartProduct(
                          id: product.id,
                          name: product.name,
                          images: product.images,
                          imageUrl:
                              product.images.isNotEmpty
                                  ? product.images.first
                                  : product.imageUrl,
                          salePrice: product.salePrice,
                          regularPrice: product.regularPrice,
                          quantity: 1,
                          addedAt: DateTime.now(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF1B4965), Color(0xFF2B729C)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFCAE9FF),
                            blurRadius: 8.1,
                            offset: Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4965),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          if (qty <= 1) {
                            await _cartService.remove(product.id);
                          } else {
                            await _cartService.setQuantity(product.id, qty - 1);
                          }
                        },
                        icon: const Icon(Icons.remove, color: Colors.white),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _cartService.addOrIncrement(
                            CartProduct(
                              id: product.id,
                              name: product.name,
                              images: product.images,
                              imageUrl:
                                  product.images.isNotEmpty
                                      ? product.images.first
                                      : product.imageUrl,
                              salePrice: product.salePrice,
                              regularPrice: product.regularPrice,
                              quantity: 1,
                              addedAt: DateTime.now(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Data class for spec rows
class _SpecRow {
  final String label;
  final String value;
  const _SpecRow(this.label, this.value);
}
