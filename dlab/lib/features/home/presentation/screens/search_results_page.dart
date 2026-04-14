import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/wishlist_service.dart';

import 'dlabs_home_page.dart';
import 'product_details_page.dart';
import '../../../notifications/presentation/screens/notifications_page.dart';
import '../../../wishlist/presentation/screens/wishlist_page.dart';
import '../widgets/filter_bottom_sheet_widget.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  static const _cityKey = 'saved_city';
  static const _countryKey = 'saved_country';

  static const Color _primary = Color(0xFF1B4965);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _orange = Color(0xFFFF5500);
  static const Color _border = Color(0xFFCAE9FF);
  static const Color _lightBg = Color(0xFFF9F9F9);
  static const Color _placeholder = Color(0xFF9DB2CE);
  static const Color _cardBorder = Color(0xFFF2F2F2);

  static const _imgProxyBase = 'http://app.dezign-lab.com:3000';
  static const Duration _maxPriceRefreshInterval = Duration(minutes: 15);

  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  final List<String> _filters = [];
  static const String _colourChipPrefix = 'Colour: ';
  static const String _priceChipPrefix = 'Price: ';
  final Set<String> _selectedPopularFilters = <String>{};
  final Set<String> _selectedBrands = <String>{};
  String _selectedColor = '';
  double _maxDatabasePrice = 1500;
  DateTime? _lastPriceMaxFetchedAt;
  RangeValues _currentPriceRange = const RangeValues(0, 1500);
  final Map<int, int> _cartQuantities = <int, int>{};
  final Map<int, List<VariantModel>> _variantCache = <int, List<VariantModel>>{};
  final CartService _cartService = CartService.instance;

  List<ProductModel> _results = <ProductModel>[];
  List<ProductModel> _recommended = <ProductModel>[];
  List<ProductModel> _queryMatchedResults = <ProductModel>[];

  bool _isLoading = true;
  String _selectedCity = 'San Antonio';
  String _selectedCountry = 'United States';
  String _sortBy = 'Relevance';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _initializeCart();
    _loadSavedLocation();
    _fetchProducts(query: widget.query);
  }

  @override
  void dispose() {
    _speechToText.stop();
    _searchController.dispose();
    super.dispose();
  }

  String _imgUrl(String url) {
    if (!kIsWeb) {
      return url;
    }
    return '$_imgProxyBase/api/image-proxy?url=${Uri.encodeComponent(url)}';
  }

  Future<void> _initializeCart() async {
    await _cartService.initialize();
    if (!mounted) {
      return;
    }

    setState(() {
      _cartQuantities
        ..clear()
        ..addAll(_cartService.getQuantities());
    });
  }

  Future<void> _addToCart(ProductModel product) async {
    await _cartService.addOrIncrement(
      CartProduct(
        id: product.id,
        name: product.name,
        images: product.images,
        imageUrl: product.images.isNotEmpty ? product.images.first : product.imageUrl,
        salePrice: product.salePrice,
        regularPrice: product.regularPrice,
        quantity: 1,
        addedAt: DateTime.now(),
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _cartQuantities
        ..clear()
        ..addAll(_cartService.getQuantities());
    });
  }

  Future<void> _increaseCartItem(ProductModel product) async {
    await _addToCart(product);
  }

  Future<void> _decreaseCartItem(ProductModel product) async {
    final current = _cartQuantities[product.id] ?? 0;
    if (current <= 1) {
      await _cartService.remove(product.id);
    } else {
      await _cartService.setQuantity(product.id, current - 1);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _cartQuantities
        ..clear()
        ..addAll(_cartService.getQuantities());
    });
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_cityKey);
    final country = prefs.getString(_countryKey);
    final legacyLocation = prefs.getString('user_location')?.trim();

    if (!mounted) {
      return;
    }

    setState(() {
      if (city != null && country != null && city.isNotEmpty) {
        _selectedCity = city;
        _selectedCountry = country;
      } else if (legacyLocation != null && legacyLocation.isNotEmpty) {
        final parts = legacyLocation.split(',').map((e) => e.trim()).toList();
        if (parts.isNotEmpty && parts.first.isNotEmpty) {
          _selectedCity = parts.first;
          _selectedCountry = parts.length > 1 ? parts.last : '';
        }
      }
    });
  }

  Future<void> _saveLocation(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, city);
    await prefs.setString(_countryKey, country);
    await prefs.setString('user_location', '$city, $country');
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => LocationPickerSheet(
            initialCity: _selectedCity,
            initialCountry: _selectedCountry,
            onApply: (city, state, country) {
              setState(() {
                _selectedCity = city;
                _selectedCountry = country;
              });
              _saveLocation(city, country);
            },
          ),
    );
  }

  Future<void> _onLocationButtonTap() async {
    final detected = await _tryDetectLocationFromDevice();
    if (!mounted) {
      return;
    }

    if (detected != null) {
      final city = detected.$1;
      final country = detected.$2;
      setState(() {
        _selectedCity = city;
        _selectedCountry = country;
      });
      await _saveLocation(city, country);
      return;
    }

    _showLocationPicker();
  }

  Future<(String, String)?> _tryDetectLocationFromDevice() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}',
      );

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'dlab-app/1.0 (search-results-location)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = (data['address'] as Map<String, dynamic>?) ?? {};

      final city =
          (address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  address['municipality'] ??
                  address['county'] ??
                  '')
              .toString()
              .trim();
      final country = (address['country'] ?? '').toString().trim();

      if (city.isEmpty || country.isEmpty) {
        return null;
      }

      return (city, country);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchProducts({required String query}) async {
    setState(() {
      _isLoading = true;
    });

    await _refreshMaxPriceFromDatabase();

    final allProducts = await ProductService.fetchProducts(limit: 120, offset: 0);
    final normalized = query.trim().toLowerCase();

    final filtered =
        allProducts.where((product) {
          final inName = product.name.toLowerCase().contains(normalized);
          final inShort =
              (product.shortDescription ?? '').toLowerCase().contains(normalized);
          final inDesc =
              (product.description ?? '').toLowerCase().contains(normalized);
          return normalized.isEmpty || inName || inShort || inDesc;
        }).toList();

    final random = Random();
    final shuffled = List<ProductModel>.from(allProducts)..shuffle(random);

    final recommended =
        shuffled
            .where((item) => !filtered.any((result) => result.id == item.id))
            .take(8)
            .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _queryMatchedResults = filtered;
      _recommended = recommended;
      _isLoading = false;
    });

    await _applyActiveFilters();
  }

  void _applySort(String value) {
    setState(() {
      _sortBy = value;
    });
    _applyActiveFilters();
  }

  void _onSubmitSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _fetchProducts(query: trimmed);
  }

  void _showFilterSheet() {
    FilterBottomSheetWidget.show(
      context,
      initialPopularFilters: Set<String>.from(_selectedPopularFilters),
      initialSelectedBrands: Set<String>.from(_selectedBrands),
      initialSelectedColor: _selectedColor,
      initialPriceRange: _currentPriceRange,
      maxPrice: _maxDatabasePrice,
      onApplySelection: (selection) {
        setState(() {
          _selectedPopularFilters
            ..clear()
            ..addAll(selection.popularFilters);

          _selectedBrands
            ..clear()
            ..addAll(selection.selectedBrands);

          _selectedColor = selection.selectedColor;
          _currentPriceRange = RangeValues(
            selection.currentPriceRange.start.clamp(0, _maxDatabasePrice),
            selection.currentPriceRange.end.clamp(0, _maxDatabasePrice),
          );
          _syncAppliedFiltersChips();
        });
        _applyActiveFilters();
      },
    );
  }

  Future<void> _triggerVoiceSearch() async {
    _showVoiceMessage('Initializing voice search...');

    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _isListening = false;
      });
      _showVoiceMessage('Stopped listening.');
      return;
    }

    final bool isAvailable = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) {
          return;
        }
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isListening = false;
        });
        _showVoiceMessage('Voice error: ${error.errorMsg}');
      },
    );

    if (!isAvailable) {
      if (!mounted) {
        return;
      }
      _showVoiceMessage(
        'Voice recognition unavailable. Allow mic permission in Chrome site settings.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = true;
    });
    _showVoiceMessage('Listening... Speak now.');

    await _speechToText.listen(
      listenMode: stt.ListenMode.search,
      partialResults: true,
      onResult: (result) {
        final String recognizedText = result.recognizedWords.trim();

        if (!mounted || recognizedText.isEmpty) {
          return;
        }

        setState(() {
          _searchController.text = recognizedText;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length),
          );
        });

        if (result.finalResult) {
          _onSubmitSearch(recognizedText);
          setState(() {
            _isListening = false;
          });
          _showVoiceMessage('Searching for "$recognizedText"');
        }
      },
    );
  }

  void _onVoiceTap() {
    _triggerVoiceSearch();
  }

  void _showVoiceMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      debugPrint('Voice message: $message');
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _removeFilter(String filter) {
    setState(() {
      if (_selectedPopularFilters.contains(filter)) {
        _selectedPopularFilters.remove(filter);
      } else if (_selectedBrands.contains(filter)) {
        _selectedBrands.remove(filter);
      } else if (filter == '$_colourChipPrefix$_selectedColor') {
        _selectedColor = '';
      } else if (filter.startsWith(_priceChipPrefix)) {
        _currentPriceRange = RangeValues(0, _maxDatabasePrice);
      }

      _syncAppliedFiltersChips();
    });
    _applyActiveFilters();
  }

  Future<void> _applyActiveFilters() async {
    List<ProductModel> filtered = List<ProductModel>.from(_queryMatchedResults);

    final double minPrice = _currentPriceRange.start;
    final double maxPrice = _currentPriceRange.end;

    filtered =
        filtered
            .where(
              (product) =>
                  product.regularPrice >= minPrice &&
                  product.regularPrice <= maxPrice,
            )
            .toList();

    final String normalizedColor = _selectedColor.trim().toLowerCase();
    if (normalizedColor.isNotEmpty) {
      filtered = await _filterByVariantColor(filtered, normalizedColor);
    }

    final bool newArrivalsSelected =
        _selectedPopularFilters.contains('New Arrivals');
    final bool onSaleSelected = _selectedPopularFilters.contains('On Sale');

    if (onSaleSelected) {
      filtered =
          filtered.where((product) {
            final sale = product.salePrice;
            return sale != null && sale < product.regularPrice;
          }).toList();

      filtered.sort(
        (a, b) => _discountAmount(b).compareTo(_discountAmount(a)),
      );
    } else if (newArrivalsSelected) {
      filtered.sort((a, b) {
        final DateTime? aDate = a.createdAt;
        final DateTime? bDate = b.createdAt;

        if (aDate != null && bDate != null) {
          return bDate.compareTo(aDate);
        }
        if (aDate != null) return -1;
        if (bDate != null) return 1;
        return b.id.compareTo(a.id);
      });
    } else {
      _sortProductsInPlace(filtered, _sortBy);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _results = filtered;
    });
  }

  Future<List<ProductModel>> _filterByVariantColor(
    List<ProductModel> products,
    String normalizedColor,
  ) async {
    final List<ProductModel> colorMatched = <ProductModel>[];

    for (final ProductModel product in products) {
      final List<VariantModel> variants = await _getVariantsForProduct(product.id);
      final bool hasColorVariant = variants.any(
        (variant) => variant.variantName.toLowerCase().contains(normalizedColor),
      );

      if (hasColorVariant) {
        colorMatched.add(product);
      }
    }

    return colorMatched;
  }

  Future<List<VariantModel>> _getVariantsForProduct(int productId) async {
    final cached = _variantCache[productId];
    if (cached != null) {
      return cached;
    }

    final fetched = await ProductService.fetchVariants(productId);
    _variantCache[productId] = fetched;
    return fetched;
  }

  void _sortProductsInPlace(List<ProductModel> products, String value) {
    switch (value) {
      case 'Price: Low to High':
        products.sort((a, b) {
          final aPrice = a.salePrice ?? a.regularPrice;
          final bPrice = b.salePrice ?? b.regularPrice;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'Price: High to Low':
        products.sort((a, b) {
          final aPrice = a.salePrice ?? a.regularPrice;
          final bPrice = b.salePrice ?? b.regularPrice;
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'Name':
        products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      default:
        products.sort((a, b) => b.id.compareTo(a.id));
    }
  }

  void _syncAppliedFiltersChips() {
    _filters
      ..clear()
      ..addAll(_selectedPopularFilters)
      ..addAll(_selectedBrands);

    if (_selectedColor.isNotEmpty) {
      _filters.add('$_colourChipPrefix$_selectedColor');
    }

    if (_currentPriceRange.start > 0 || _currentPriceRange.end < _maxDatabasePrice) {
      _filters.add(
        '$_priceChipPrefix\$${_currentPriceRange.start.toInt()} - \$${_currentPriceRange.end.toInt()}',
      );
    }
  }

  Future<void> _refreshMaxPriceFromDatabase() async {
    final now = DateTime.now();
    if (_lastPriceMaxFetchedAt != null &&
        now.difference(_lastPriceMaxFetchedAt!) < _maxPriceRefreshInterval) {
      return;
    }

    final fetched = await ProductService.fetchMaxProductPrice(
      ttl: _maxPriceRefreshInterval,
    );
    _lastPriceMaxFetchedAt = now;

    if (!mounted) {
      return;
    }

    if ((fetched - _maxDatabasePrice).abs() < 0.5) {
      return;
    }

    setState(() {
      _maxDatabasePrice = fetched;
      _currentPriceRange = RangeValues(
        _currentPriceRange.start.clamp(0, _maxDatabasePrice),
        _currentPriceRange.end.clamp(0, _maxDatabasePrice),
      );
      if (_currentPriceRange.start > _currentPriceRange.end) {
        _currentPriceRange = RangeValues(0, _maxDatabasePrice);
      }
      _syncAppliedFiltersChips();
    });
  }

  double _discountAmount(ProductModel product) {
    final sale = product.salePrice;
    if (sale == null || sale >= product.regularPrice) {
      return 0;
    }
    return product.regularPrice - sale;
  }

  void _onSelectBottomPage(int pageIndex) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(initialIndex: pageIndex)),
    );
  }

  void _goToHomePage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
      (route) => false,
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _openWishlist() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WishlistPage()),
    );
  }

  int _discountPct(ProductModel product) {
    if (product.salePrice == null || product.regularPrice <= 0) {
      return 0;
    }
    return (((product.regularPrice - product.salePrice!) / product.regularPrice) * 100)
        .round();
  }

  String _formatRs(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            _buildHeaderSliver(screenWidth),
            _buildSearchBarSliver(screenWidth),
            if (_filters.isNotEmpty) _buildAppliedFiltersSliver(screenWidth),
            SliverToBoxAdapter(child: _buildContent(screenWidth)),
          ],
        ),
      ),
      bottomNavigationBar: _HomeLikeBottomNavBar(
        currentIndex: 0,
        onSelectPage: _onSelectBottomPage,
      ),
    );
  }

  Widget _buildHeaderSliver(double screenWidth) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _goToHomePage,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF1B4965),
                        ),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _headerActionButton(
                      Icons.notifications_outlined,
                      onTap: _openNotifications,
                    ),
                    const SizedBox(width: 8),
                    _headerActionButton(
                      Icons.favorite_border_rounded,
                      onTap: _openWishlist,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _onLocationButtonTap,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: Color(0xFFFF5500),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_selectedCity, $_selectedCountry',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerActionButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _primary, size: 24),
      ),
    );
  }

  SliverAppBar _buildSearchBarSliver(double screenWidth) {
    final hPad = screenWidth * 0.05;
    final iconSize = screenWidth * 0.06;

    return SliverAppBar(
      primary: false,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 72,
      titleSpacing: hPad,
      title: Container(
        height: 60,
        decoration: BoxDecoration(
          color: _lightBg,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(width: screenWidth * 0.02),
            Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _showFilterSheet,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.018),
                    child: Image.asset(
                      'assets/images/filter.png',
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (_filters.isNotEmpty)
                  const Positioned(
                    right: 1,
                    top: 1,
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: screenWidth * 0.015),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSubmitSearch,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: _textPrimary,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: _placeholder,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: screenWidth * 0.08,
              color: _border,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _onVoiceTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenWidth * 0.02,
                ),
                child: Image.asset(
                  'assets/icons/mic.png',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppliedFiltersSliver(double screenWidth) {
    final hPad = screenWidth * 0.05;

    return SliverAppBar(
      primary: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: _bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 48,
      titleSpacing: hPad,
      title: SizedBox(
        height: screenWidth * 0.1,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.036,
                vertical: screenWidth * 0.018,
              ),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(29),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.012),
                  InkWell(
                    onTap: () => _removeFilter(filter),
                    child: const Icon(Icons.close, size: 16, color: _primary),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => SizedBox(width: screenWidth * 0.02),
          itemCount: _filters.length,
        ),
      ),
    );
  }

  Widget _buildContent(double screenWidth) {
    final hPad = screenWidth * 0.05;
    final sectionGap = screenWidth * 0.06;
    final topPad = _filters.isEmpty ? 0.0 : sectionGap * 0.5;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (_results.isEmpty) {
      final imageWidth = (screenWidth * 0.82).clamp(220.0, 326.11);
      final imageHeight = imageWidth * (260 / 326.11);

      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.16),
          child: Center(
            child: SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: Image.asset(
                'assets/no.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, sectionGap * 1.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: _searchController.text.trim().isEmpty
                ? 'Search Results'
                : _searchController.text.trim(),
            showSort: true,
          ),
          SizedBox(height: screenWidth * 0.025),
          _buildProductGrid(screenWidth: screenWidth, products: _results),
          if (_recommended.isNotEmpty) ...[
            SizedBox(height: sectionGap),
            const Text(
              'Recommended',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: screenWidth * 0.025),
            _buildProductGrid(screenWidth: screenWidth, products: _recommended),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required bool showSort}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
        if (showSort)
          PopupMenuButton<String>(
            color: Colors.white,
            onSelected: _applySort,
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'Relevance', child: Text('Relevance')),
                  PopupMenuItem(
                    value: 'Price: Low to High',
                    child: Text('Price: Low to High'),
                  ),
                  PopupMenuItem(
                    value: 'Price: High to Low',
                    child: Text('Price: High to Low'),
                  ),
                  PopupMenuItem(value: 'Name', child: Text('Name')),
                ],
            child: Row(
              children: [
                Text(
                  _sortBy,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductGrid({
    required double screenWidth,
    required List<ProductModel> products,
  }) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No products found.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: _muted,
          ),
        ),
      );
    }

    const gap = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              products
                  .map(
                    (product) => SizedBox(
                      width: cardWidth,
                      child: _SearchProductCard(
                        product: product,
                        imageUrlBuilder: _imgUrl,
                        discountPct: _discountPct(product),
                        quantity: _cartQuantities[product.id] ?? 0,
                        formatRs: _formatRs,
                        onAdd: () async {
                          await _addToCart(product);
                        },
                        onIncrease: () async {
                          await _increaseCartItem(product);
                        },
                        onDecrease: () async {
                          await _decreaseCartItem(product);
                        },
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _SearchProductCard extends StatefulWidget {
  final ProductModel product;
  final String Function(String url) imageUrlBuilder;
  final int discountPct;
  final int quantity;
  final String Function(double value) formatRs;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _SearchProductCard({
    required this.product,
    required this.imageUrlBuilder,
    required this.discountPct,
    required this.quantity,
    required this.formatRs,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  State<_SearchProductCard> createState() => _SearchProductCardState();
}

class _SearchProductCardState extends State<_SearchProductCard> {
  static const Color _primary = Color(0xFF1B4965);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _orange = Color(0xFFFF5500);
  static const Color _cardBorder = Color(0xFFF2F2F2);

  final WishlistService _wishlistService = WishlistService.instance;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardHeight = width * (232 / 189);
        final imageHeight = cardHeight * 0.43;
        final buttonHeight = (width * 0.18).clamp(34.0, 40.0);
        final hasSale = widget.product.salePrice != null &&
            widget.product.salePrice! < widget.product.regularPrice;
        final displayPrice =
            hasSale ? widget.product.salePrice! : widget.product.regularPrice;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsPage(
                  product: widget.product,
                  sourceTabIndex: 0,
                ),
              ),
            );
          },
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(width * 0.053),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child:
                            widget.product.imageUrl != null
                              ? Image.network(
                              widget.imageUrlBuilder(widget.product.imageUrl!),
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder:
                                    (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.devices_other_rounded,
                                        color: Color(0xFFCAE9FF),
                                        size: 48,
                                      ),
                                    ),
                              )
                              : const Center(
                                child: Icon(
                                  Icons.devices_other_rounded,
                                  color: Color(0xFFCAE9FF),
                                  size: 48,
                                ),
                              ),
                    ),
                    Positioned(
                      left: 0,
                      top: width * 0.015,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.032,
                          vertical: width * 0.016,
                        ),
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '4.6',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: width * 0.055,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: width * 0.01),
                            Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: width * 0.06,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: width * 0.015,
                      child: ValueListenableBuilder<Set<int>>(
                        valueListenable: _wishlistService.likedIds,
                        builder: (context, likedIds, _) {
                          final isLiked = likedIds.contains(widget.product.id);
                          return InkWell(
                            onTap: _toggleWishlist,
                            borderRadius: BorderRadius.circular(29),
                            child: Container(
                              width: width * 0.17,
                              height: width * 0.17,
                              decoration: BoxDecoration(
                                color: const Color(0x19191919),
                                borderRadius: BorderRadius.circular(29),
                              ),
                              child: Center(
                                child: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border_rounded,
                                  size: 16,
                                  color: isLiked ? _primary : _textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: width * 0.03),
                Text(
                  widget.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: width * 0.074,
                    fontWeight: FontWeight.w400,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: width * 0.016),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.formatRs(displayPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: width * 0.062,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    if (hasSale)
                      Wrap(
                        spacing: width * 0.02,
                        runSpacing: 2,
                        children: [
                          Text(
                            widget.formatRs(widget.product.regularPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: width * 0.052,
                              color: const Color(0xFF757575),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (widget.discountPct > 0)
                            Text(
                              '${widget.discountPct}% off',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: width * 0.052,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                const Spacer(),
                if (widget.quantity == 0)
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: widget.onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: width * 0.085,
                          ),
                          SizedBox(width: width * 0.02),
                          Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: width * 0.064,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCAE9FF)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: IconButton(
                            onPressed: widget.onDecrease,
                            icon: Icon(
                              Icons.remove,
                              color: _primary,
                              size: width * 0.09,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        Text(
                          '${widget.quantity}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: _primary,
                            fontSize: width * 0.07,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            onPressed: widget.onIncrease,
                            icon: Icon(
                              Icons.add,
                              color: _primary,
                              size: width * 0.09,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeLikeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectPage;

  const _HomeLikeBottomNavBar({
    required this.currentIndex,
    required this.onSelectPage,
  });

  void _handleTap(int index) {
    final pageIndex = index > 2 ? index - 1 : index;
    onSelectPage(pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final barHeight = (w * 0.145).clamp(56.0, 72.0);
          final totalHeight = barHeight;
          final centerSize = (barHeight * 0.9).clamp(52.0, 68.0);
          final iconSize = (w * 0.06).clamp(22.0, 26.0);
          final labelSize = (w * 0.03).clamp(11.0, 13.0);

          return Container(
            height: totalHeight,
            color: AppColors.darkBg,
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
                          child: _NavItemImage(
                            index: 0,
                            currentIndex: currentIndex,
                            assetPath: 'assets/icons/home.png',
                            label: 'Home',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            onTap: _handleTap,
                          ),
                        ),
                        Expanded(
                          child: _NavItemImage(
                            index: 1,
                            currentIndex: currentIndex,
                            assetPath: 'assets/icons/category.png',
                            label: 'Categories',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            onTap: _handleTap,
                          ),
                        ),
                        SizedBox(width: centerSize * 0.7),
                        Expanded(
                          child: _NavItemImage(
                            index: 3,
                            currentIndex: currentIndex,
                            assetPath: 'assets/icons/cart.png',
                            label: 'Cart',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            onTap: _handleTap,
                          ),
                        ),
                        Expanded(
                          child: _NavItemImage(
                            index: 4,
                            currentIndex: currentIndex,
                            assetPath: 'assets/icons/user.png',
                            label: 'Profile',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            onTap: _handleTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: barHeight - (centerSize * 0.75),
                  child: Container(
                    width: centerSize,
                    height: centerSize,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.darkBg,
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavItemImage extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String assetPath;
  final String label;
  final double iconSize;
  final double labelSize;
  final ValueChanged<int> onTap;

  const _NavItemImage({
    required this.index,
    required this.currentIndex,
    required this.assetPath,
    required this.label,
    required this.iconSize,
    required this.labelSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
            color: isActive ? AppColors.navActive : AppColors.navInactive,
          ),
          SizedBox(height: labelSize * 0.4),
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              color: isActive ? AppColors.navActive : AppColors.navInactive,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
