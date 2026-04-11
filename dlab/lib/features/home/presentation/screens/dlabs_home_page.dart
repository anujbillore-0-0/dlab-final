import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../notifications/presentation/screens/notifications_page.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../wishlist/presentation/screens/wishlist_page.dart';
import 'checkout_screen.dart';
import 'product_details_page.dart';
import 'search_page.dart';
import 'search_results_page.dart';

// ─────────────────────────────────────────────
// HOME PAGE ENTRY (router target)
// ─────────────────────────────────────────────
class DLabsHomePage extends StatelessWidget {
  const DLabsHomePage({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context) => const MainShell();
}

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFF1B4965);
  static const secondary = Color(0xFF62B6CB);
  static const secondBlue = Color(0xFF27C4F4);
  static const bgLight = Color(0xFFF4F9FF);
  static const border = Color(0xFFCAE9FF);
  static const cardBorder = Color(0xFFF2F2F2);
  static const muted = Color(0xFF6B7280);
  static const textPrimary = Color(0xFF111827);
  static const darkBg = Color(0xFF111827);
  static const navActive = Color(0xFF62B6CB);
  static const navInactive = Color(0xFF676D75);
  static const red = Color(0xFFFF0005);
}

const Map<String, String> _categoryLogos = {
  'ACTION CAM LAB': 'assets/logos/action_cam_lab.png',
  'AUDIO LAB': 'assets/logos/audio_lab.png',
  'BAGS & CASES LAB': 'assets/logos/audio_lab.png',
  'CABLE LAB': 'assets/logos/cable_lab.png',
  'CAR ACCESSORY LAB': 'assets/logos/car_accessory_lab.png',
  'DISPLAY LAB': 'assets/logos/display_lab.png',
  'DORAEMON': 'assets/logos/doraemon_lab.png',
  'EDUCATION LAB': 'assets/logos/energy_lab.png',
  'ENERGY LAB': 'assets/logos/energy_lab.png',
  'GAMING LAB': 'assets/logos/action_cam_lab.png',
  'HEALTH LAB': 'assets/logos/audio_lab.png',
  'HOME LAB': 'assets/logos/cable_lab.png',
  'KIDS & TOYS LAB': 'assets/logos/car_accessory_lab.png',
  'MOBILITY LAB': 'assets/logos/display_lab.png',
  'OFFICE LAB': 'assets/logos/doraemon_lab.png',
  'OUTDOOR LAB': 'assets/logos/energy_lab.png',
  'PC LAB': 'assets/logos/action_cam_lab.png',
  'PETS LAB': 'assets/logos/audio_lab.png',
  'ROBOT LAB': 'assets/logos/cable_lab.png',
  'SECURITY LAB': 'assets/logos/car_accessory_lab.png',
  'SHINCHAN': 'assets/logos/doraemon_lab.png',
  'SMART LAB': 'assets/logos/display_lab.png',
};

// ─────────────────────────────────────────────
// MAIN SHELL (with bottom nav)
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomePage(),
    CategoriesPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onSelectPage: (pageIndex) => setState(() => _currentIndex = pageIndex),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectPage;

  const _BottomNavBar({required this.currentIndex, required this.onSelectPage});

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
    final pageIndex = index > 2 ? index - 1 : index;
    final isActive = currentIndex == pageIndex;
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

// ─────────────────────────────────────────────
// HOME PAGE
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _cityKey = 'saved_city';
  static const _countryKey = 'saved_country';

  final ScrollController _scrollController = ScrollController();
  String _selectedCity = 'San Antonio';
  String _selectedCountry = 'United States';
  final List<ProductModel> _infiniteProducts = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 10;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreProducts();
    _loadSavedLocation();
    unawaited(_autoDetectLocationFromDevice());
  }

  @override
  void dispose() {
    _speechToText.stop();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            _buildStickySearch(),
            SliverToBoxAdapter(child: _buildBody()),
            SliverToBoxAdapter(child: _buildTrustBadges()),
            _buildInfiniteProductsGrid(),
            SliverToBoxAdapter(child: _buildInfiniteFooter()),
          ],
        ),
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final threshold = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= threshold) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final products = await ProductService.fetchProducts(
      limit: _pageSize,
      offset: _offset,
    );
    if (!mounted) return;
    setState(() {
      _infiniteProducts.addAll(products);
      _offset += products.length;
      _isLoadingMore = false;
      if (products.length < _pageSize) _hasMore = false;
    });
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_cityKey);
    final country = prefs.getString(_countryKey);
    if (city != null && country != null && city.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedCity = city;
          _selectedCountry = country;
        });
      }
    }
  }

  Future<void> _saveLocation(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, city);
    await prefs.setString(_countryKey, country);
  }

  Future<void> _autoDetectLocationFromDevice() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}',
      );

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'dlab-app/1.0 (home-location)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) return;

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

      if (city.isEmpty || country.isEmpty) return;

      if (!mounted) return;

      setState(() {
        _selectedCity = city;
        _selectedCountry = country;
      });

      await _saveLocation(city, country);
    } catch (_) {}
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }

  void _openWishlist() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WishlistPage()));
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

        if (result.finalResult) {
          setState(() {
            _isListening = false;
          });
          _showVoiceMessage('Searching for "$recognizedText"');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SearchResultsPage(query: recognizedText),
            ),
          );
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

  Widget _buildTrustBadges() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(height: 0.5, color: const Color(0xFF9DB2CE)),
        const TrustBadgesRow(),
        Container(height: 0.5, color: const Color(0xFF9DB2CE)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfiniteFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox(height: 80);
  }

  SliverToBoxAdapter _buildInfiniteProductsGrid() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _ProductGrid(products: _infiniteProducts),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                Row(
                  children: [
                    _iconButton(
                      Icons.notifications_outlined,
                      onTap: _openNotifications,
                    ),
                    const SizedBox(width: 8),
                    _iconButton(
                      Icons.favorite_border_rounded,
                      onTap: _openWishlist,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _showLocationPicker,
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
                      color: AppColors.textPrimary,
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

  Widget _iconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }

  SliverAppBar _buildStickySearch() {
    return SliverAppBar(
      primary: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 68,
      title: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(width: 12),
              Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search products...',
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(21.5),
                onTap: _onVoiceTap,
                child: Container(
                  width: 43,
                  height: 43,
                  padding: const EdgeInsets.fromLTRB(12, 12, 11, 11),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(21.5),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/icons/mic.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      titleSpacing: 20,
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const BannerSlider(),
        const SizedBox(height: 20),
        const QuickLinksRow(),
        const SizedBox(height: 20),
        const CategoriesSection(),
        const SizedBox(height: 20),
        ProductSection(title: 'Top Deals', showSeeAll: true),
        const SizedBox(height: 12),
        const PromoBanner(),
        const SizedBox(height: 16),
        const TrendingSection(),
        const SizedBox(height: 20),
        const AdBanner(),
        const SizedBox(height: 20),
        ProductSection(
          title: 'Discover products for you',
          saleOnly: true,
          limit: 4,
          showSeeAll: true,
        ),
        const ResponsiveDealsSection(),
        const SizedBox(height: 20),
        ProductSection(title: 'New Arrivals', offset: 40),
      ],
    );
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
}

// ─────────────────────────────────────────────
// NOMINATIM LOCATION MODEL
// ─────────────────────────────────────────────
class LocationResult {
  final String displayName;
  final String city;
  final String state;
  final String country;
  final String countryCode;

  const LocationResult({
    required this.displayName,
    required this.city,
    required this.state,
    required this.country,
    required this.countryCode,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    final addr = (json['address'] as Map<String, dynamic>?) ?? {};
    final city =
        addr['city'] as String? ??
        addr['town'] as String? ??
        addr['village'] as String? ??
        addr['municipality'] as String? ??
        addr['county'] as String? ??
        '';
    final state = addr['state'] as String? ?? '';
    final country = addr['country'] as String? ?? '';
    final code = addr['country_code'] as String? ?? '';
    final parts = [city, state, country].where((s) => s.isNotEmpty).toList();
    final display =
        parts.isNotEmpty
            ? parts.join(', ')
            : json['display_name'] as String? ?? '';
    return LocationResult(
      displayName: display,
      city: city,
      state: state,
      country: country,
      countryCode: code.toUpperCase(),
    );
  }
}

// ─────────────────────────────────────────────
// NOMINATIM SERVICE
// ─────────────────────────────────────────────
class NominatimService {
  static const _nominatim = 'https://nominatim.openstreetmap.org';
  static const _corsProxy = 'https://corsproxy.io/?';

  static Future<List<LocationResult>> search(
    String query, {
    int limit = 7,
  }) async {
    if (query.trim().length < 2) return [];

    final nominatimPath =
        '$_nominatim/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=$limit';

    final uri = Uri.parse(
      kIsWeb
          ? '$_corsProxy${Uri.encodeComponent(nominatimPath)}'
          : nominatimPath,
    );

    try {
      final headers =
          kIsWeb
              ? <String, String>{}
              : <String, String>{
                'User-Agent': 'DLabApp/1.0 (contact@dezign-lab.com)',
                'Accept': 'application/json',
              };

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final seen = <String>{};
      final results = <LocationResult>[];
      for (final item in data) {
        final r = LocationResult.fromJson(item as Map<String, dynamic>);
        final key = '${r.city}|${r.country}';
        if (r.city.isNotEmpty && seen.add(key)) results.add(r);
      }
      return results;
    } catch (_) {
      return [];
    }
  }
}

// ─────────────────────────────────────────────
// PRODUCT MODEL
// ─────────────────────────────────────────────
class ProductModel {
  final int id;
  final String name;
  final List<String> images;
  final String? imageUrl; // first image — kept for backward compat
  final double? salePrice;
  final double regularPrice;
  final int? categoryId;
  final String? shortDescription;
  final String? description;
  final bool isVariable;
  final String? length;
  final String? width;
  final String? height;

  const ProductModel({
    required this.id,
    required this.name,
    this.images = const [],
    this.imageUrl,
    this.salePrice,
    required this.regularPrice,
    this.categoryId,
    this.shortDescription,
    this.description,
    this.isVariable = false,
    this.length,
    this.width,
    this.height,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final imgRaw = json['images'];
    final imgs =
        imgRaw is List ? imgRaw.whereType<String>().toList() : <String>[];
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      images: imgs,
      imageUrl: imgs.isNotEmpty ? imgs[0] : null,
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      regularPrice: (json['regular_price'] as num?)?.toDouble() ?? 0,
      categoryId: json['category_id'] as int?,
      shortDescription: json['short_description'] as String?,
      description: json['description'] as String?,
      isVariable: json['is_variable'] as bool? ?? false,
      length: json['Length'] as String?,
      width: json['Width'] as String?,
      height: json['Height'] as String?,
    );
  }
}

// ─────────────────────────────────────────────
// PRODUCT SERVICE  (Supabase REST — anon key + RLS)
// ─────────────────────────────────────────────
class ProductService {
  static const _url = 'https://zzqeibxwasikdmdoijfb.supabase.co';
  static const _key =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6cWVpYnh3YXNpa2RtZG9pamZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5OTQwMTAsImV4cCI6MjA4NzU3MDAxMH0'
      '.guvKAPuNIw8Ln5m-r6i99eGu2tOjuHvNArYfh9Q2Prk';

  static Map<String, String> get _h => {
    'apikey': _key,
    'Authorization': 'Bearer $_key',
  };

  static Future<List<ProductModel>> fetchProducts({
    int limit = 10,
    int offset = 0,
    bool saleOnly = false,
    int? categoryId,
  }) async {
    final buf = StringBuffer(
      '$_url/rest/v1/products'
      '?select=id,name,images,sale_price,regular_price,category_id,short_description,description,is_variable'
      '&is_active=eq.true'
      '&order=id.desc'
      '&limit=$limit'
      '&offset=$offset',
    );
    if (saleOnly) buf.write('&sale_price=not.is.null');
    if (categoryId != null) buf.write('&category_id=eq.$categoryId');
    try {
      final r = await http.get(Uri.parse(buf.toString()), headers: _h);
      if (r.statusCode != 200) return [];
      return (jsonDecode(r.body) as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$_url/rest/v1/categories?select=id,name,slug&order=name.asc',
        ),
        headers: _h,
      );
      if (r.statusCode != 200) return [];
      return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<List<VariantModel>> fetchVariants(int productId) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$_url/rest/v1/product_variants'
          '?select=id,variant_name,images,sale_price,regular_price'
          '&product_id=eq.$productId'
          '&is_active=eq.true'
          '&order=id.asc',
        ),
        headers: _h,
      );
      if (r.statusCode != 200) return [];
      return (jsonDecode(r.body) as List)
          .map((e) => VariantModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<ProductModel?> fetchProductById(int id) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$_url/rest/v1/products'
          '?select=id,name,images,sale_price,regular_price,category_id,'
          'short_description,description,is_variable,Length,Width,Height'
          '&id=eq.$id'
          '&is_active=eq.true'
          '&limit=1',
        ),
        headers: _h,
      );
      if (r.statusCode != 200) return null;
      final list = jsonDecode(r.body) as List;
      if (list.isEmpty) return null;
      return ProductModel.fromJson(list[0] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────
// VARIANT MODEL
// ─────────────────────────────────────────────
class VariantModel {
  final int id;
  final String variantName;
  final List<String> images;
  final double? salePrice;
  final double? regularPrice;

  const VariantModel({
    required this.id,
    required this.variantName,
    required this.images,
    this.salePrice,
    this.regularPrice,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    final imgRaw = json['images'];
    final imgs =
        imgRaw is List ? imgRaw.whereType<String>().toList() : <String>[];
    return VariantModel(
      id: json['id'] as int,
      variantName: json['variant_name'] as String? ?? '',
      images: imgs,
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      regularPrice: (json['regular_price'] as num?)?.toDouble(),
    );
  }
}

// ─────────────────────────────────────────────
// LOCATION PICKER SHEET
// ─────────────────────────────────────────────
class LocationPickerSheet extends StatefulWidget {
  final String initialCity;
  final String initialCountry;
  final void Function(String city, String state, String country) onApply;

  const LocationPickerSheet({
    required this.initialCity,
    required this.initialCountry,
    required this.onApply,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  List<LocationResult> _suggestions = [];
  LocationResult? _selected;
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = '${widget.initialCity}, ${widget.initialCountry}';
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await NominatimService.search(value);
      if (mounted)
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
    });
  }

  void _selectResult(LocationResult r) {
    setState(() {
      _selected = r;
      _suggestions = [];
      _searchController.text = r.displayName;
    });
    _focusNode.unfocus();
  }

  void _apply() {
    if (_selected != null) {
      widget.onApply(_selected!.city, _selected!.state, _selected!.country);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Select Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Type a city or area to search',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. Mumbai, London, New York...',
                        hintStyle: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        suffixIcon:
                            _isLoading
                                ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                                : _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.muted,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _suggestions = [];
                                      _selected = null;
                                    });
                                  },
                                )
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_suggestions.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: _suggestions.length,
                  separatorBuilder:
                      (_, __) =>
                          const Divider(height: 1, color: AppColors.cardBorder),
                  itemBuilder: (ctx, i) {
                    final r = _suggestions[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        r.city.isNotEmpty ? r.city : r.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle:
                          r.state.isNotEmpty || r.country.isNotEmpty
                              ? Text(
                                [
                                  r.state,
                                  r.country,
                                ].where((s) => s.isNotEmpty).join(', '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              )
                              : null,
                      trailing: Text(
                        r.countryCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                      onTap: () => _selectResult(r),
                    );
                  },
                ),
              ),
            if (!_isLoading &&
                _suggestions.isEmpty &&
                _searchController.text.trim().length >= 2 &&
                _selected == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'No results found. Try another name.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selected!.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _selected != null ? AppColors.primary : AppColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _selected != null ? 2 : 0,
                  ),
                  onPressed: _selected != null ? _apply : null,
                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

// ─────────────────────────────────────────────
// BANNER SLIDER
// ─────────────────────────────────────────────
class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _banners = [
    'assets/images/banners/banner1.png',
    'assets/images/banners/banner2.png',
    'assets/images/banners/banner1.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        final next = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final bannerWidth = (maxW - 40).clamp(280.0, 760.0);
        final bannerHeight = (bannerWidth * 0.45).clamp(150.0, 240.0);
        return Column(
          children: [
            SizedBox(
              height: bannerHeight,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _banners.length,
                itemBuilder:
                    (ctx, i) => _buildBannerCard(
                      _banners[i],
                      bannerWidth,
                      bannerHeight,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        isActive ? AppColors.primary : const Color(0xFFCFCFCF),
                    borderRadius: BorderRadius.circular(34),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannerCard(String imagePath, double w, double h) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: SizedBox(
          width: w,
          height: h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROMO BANNER
// ─────────────────────────────────────────────
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 390 / 134,
          child: Image.asset(
            'assets/images/promo/banner.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// QUICK LINKS ROW
// ─────────────────────────────────────────────
class QuickLinksRow extends StatelessWidget {
  const QuickLinksRow({super.key});

  static const _items = [
    {
      'label': 'Deals',
      'asset': 'assets/icons/quick_actions/sale.png',
      'bg': Color(0xFFFFE7DA),
    },
    {
      'label': 'Free Shipping',
      'asset': 'assets/icons/quick_actions/free.png',
      'bg': Color(0xFFE6F9ED),
    },
    {
      'label': 'Under ₹999',
      'asset': 'assets/icons/quick_actions/gift.png',
      'bg': Color(0xFFE9F2FE),
    },
    {
      'label': 'New',
      'asset': 'assets/icons/quick_actions/new.png',
      'bg': Color(0xFFF3EEFF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            _items
                .map(
                  (item) => Expanded(
                    child: _QuickLinkItem(
                      label: item['label'] as String,
                      assetPath: item['asset'] as String,
                      bgColor: item['bg'] as Color,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _QuickLinkItem extends StatelessWidget {
  final String label;
  final String assetPath;
  final Color bgColor;

  const _QuickLinkItem({
    required this.label,
    required this.assetPath,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = (MediaQuery.of(context).size.width / 7).clamp(
      52.0,
      68.0,
    );
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(circleSize * 0.2),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORIES SECTION
// ─────────────────────────────────────────────
class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  static Map<String, String> get _logos => _categoryLogos;

  static const List<String> categories = [
    'ACTION CAM LAB',
    'AUDIO LAB',
    'BAGS & CASES LAB',
    'CABLE LAB',
    'CAR ACCESSORY LAB',
    'DISPLAY LAB',
    'DORAEMON',
    'EDUCATION LAB',
    'ENERGY LAB',
    'GAMING LAB',
    'HEALTH LAB',
    'HOME LAB',
    'KIDS & TOYS LAB',
    'MOBILITY LAB',
    'OFFICE LAB',
    'OUTDOOR LAB',
    'PC LAB',
    'PETS LAB',
    'ROBOT LAB',
    'SECURITY LAB',
    'SHINCHAN',
    'SMART LAB',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories For you',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => const CategoriesPage(showBottomNav: true),
                      ),
                    ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 1.0,
                    color: Color(0xFFFF5500),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder:
                (ctx, i) => GestureDetector(
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => CategoriesPage(
                                initialCategory: categories[i],
                                showBottomNav: true,
                              ),
                        ),
                      ),
                  child: _CategoryItem(label: categories[i]),
                ),
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  const _CategoryItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
              width: 1,
            ),
            color: AppColors.bgLight,
          ),
          child: Builder(
            builder: (context) {
              final logo = CategoriesSection._logos[label];
              if (logo != null) {
                return ClipOval(
                  child: Image.asset(
                    logo,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Center(
                          child: Text(
                            label.substring(0, 1),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                  ),
                );
              }
              return Center(
                child: Text(
                  label.substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PRODUCT SECTION
// ─────────────────────────────────────────────
class ProductSection extends StatefulWidget {
  final String title;
  final int offset;
  final bool saleOnly;
  final int limit;
  final bool showSeeAll;

  const ProductSection({
    super.key,
    required this.title,
    this.offset = 0,
    this.saleOnly = false,
    this.limit = 10,
    this.showSeeAll = false,
  });

  @override
  State<ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends State<ProductSection> {
  late final Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProductService.fetchProducts(
      limit: widget.limit,
      offset: widget.offset,
      saleOnly: widget.saleOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (widget.showSeeAll)
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          height: 1.0,
                          color: Color(0xFFFF5500),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (widget.title == 'Top Deals')
              LayoutBuilder(
                builder: (context, constraints) {
                  // Card at width 160 renders:
                  // image 122 + gap 10 + name ~42 + gap 6 + price ~43 + gap 10 + button 40 + padding 20 = ~293
                  // Use 310 to give slight breathing room without a large gap
                  const double cardWidth = 160.0;
                  const double listHeight = 285.0;
                  return SizedBox(
                    height: listHeight,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder:
                          (ctx, i) => SizedBox(
                            width: cardWidth,
                            child: _ProductCard(product: products[i]),
                          ),
                    ),
                  );
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ProductGrid(products: products),
              ),
          ],
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final int sourceTabIndex;
  const _ProductGrid({required this.products, this.sourceTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 50) / 2;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          products
              .map(
                (p) => SizedBox(
                  width: w,
                  child: _ProductCard(
                    product: p,
                    sourceTabIndex: sourceTabIndex,
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ProductModel product;
  final int sourceTabIndex;
  const _ProductCard({required this.product, this.sourceTabIndex = 0});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  final WishlistService _wishlistService = WishlistService.instance;

  String _fmt(double price) => '\$${price.toStringAsFixed(0)}';

  /// On web, images from dezign-lab.com are routed through our own backend
  /// proxy so we avoid CORS errors AND WordPress hotlink-protection 403s
  /// that third-party proxies (e.g. corsproxy.io) trigger.
  static const _imgProxyBase = 'http://app.dezign-lab.com:3000';

  String _imgUrl(String url) =>
      kIsWeb
          ? '$_imgProxyBase/api/image-proxy?url=${Uri.encodeComponent(url)}'
          : url;

  int _discountPct() {
    final sp = widget.product.salePrice;
    if (sp == null || widget.product.regularPrice == 0) return 0;
    return ((widget.product.regularPrice - sp) /
            widget.product.regularPrice *
            100)
        .round();
  }

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
    final hasSale =
        widget.product.salePrice != null &&
        widget.product.salePrice! < widget.product.regularPrice;
    final displayPrice =
        hasSale ? widget.product.salePrice! : widget.product.regularPrice;
    final discount = _discountPct();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder:
                  (_) => ProductDetailsPage(
                    product: widget.product,
                    sourceTabIndex: widget.sourceTabIndex,
                  ),
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
                  height: 100,
                  width: double.infinity,
                  child:
                      widget.product.imageUrl != null
                          ? Image.network(
                            _imgUrl(widget.product.imageUrl!),
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.devices_other_rounded,
                                    size: 72,
                                    color: AppColors.border,
                                  ),
                                ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.devices_other_rounded,
                              size: 72,
                              color: AppColors.border,
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
                Positioned(
                  right: 0,
                  top: 8,
                  child: ValueListenableBuilder<Set<int>>(
                    valueListenable: _wishlistService.likedIds,
                    builder: (context, likedIds, _) {
                      final isLiked = likedIds.contains(widget.product.id);
                      return InkWell(
                        onTap: _toggleWishlist,
                        borderRadius: BorderRadius.circular(29),
                        child: Container(
                          width: 28,
                          height: 28,
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
                              color:
                                  isLiked
                                      ? AppColors.primary
                                      : const Color(0xFF111827),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Text(
                widget.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmt(displayPrice),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  if (hasSale)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _fmt(widget.product.regularPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$discount% off',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                await CartService.instance.addOrIncrement(
                  CartProduct(
                    id: widget.product.id,
                    name: widget.product.name,
                    images: widget.product.images,
                    imageUrl:
                        widget.product.images.isNotEmpty
                            ? widget.product.images.first
                            : widget.product.imageUrl,
                    salePrice: widget.product.salePrice,
                    regularPrice: widget.product.regularPrice,
                    quantity: 1,
                    addedAt: DateTime.now(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF1B4965), Color(0xFF2B729C)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFCAE9FF),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Add to Cart',
                            maxLines: 1,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TRENDING SECTION
// ─────────────────────────────────────────────
class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key});

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  late final Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProductService.fetchProducts(limit: 4, offset: 20);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Trending in your Area',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        height: 1.0,
                        color: Color(0xFFFF5500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ProductGrid(products: products),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// AD BANNER
// ─────────────────────────────────────────────
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 388 / 142,
          child: Image.asset('assets/promo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DEALS AND OFFERS SECTION
// ─────────────────────────────────────────────
class ResponsiveDealsSection extends StatelessWidget {
  const ResponsiveDealsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Deals & Offers',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 1.0,
                    color: Color(0xFFFF5500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(
                child: DealCard(
                  title: 'Electronics',
                  subtitle: 'Up to 40% off',
                  borderColor: Color(0xFF0095FF),
                  imagePath: 'assets/offertwo.png',
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: DealCard(
                  title: 'Home Lab',
                  subtitle: 'Up to 40% off',
                  borderColor: Color(0xFFFF5500),
                  imagePath: 'assets/offerone.png',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DealCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color borderColor;
  final String imagePath;

  const DealCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 184 / 190,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TRUST BADGES ROW — infinite auto-scrolling marquee
// ─────────────────────────────────────────────
class TrustBadgesRow extends StatefulWidget {
  const TrustBadgesRow({super.key});

  @override
  State<TrustBadgesRow> createState() => _TrustBadgesRowState();
}

class _TrustBadgesRowState extends State<TrustBadgesRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _badges = [
    {'icon': Icons.lock_outlined, 'label': 'Secure Payment'},
    {'icon': Icons.replay_rounded, 'label': 'Easy Return'},
    {'icon': Icons.verified_outlined, 'label': 'Verified Sellers'},
    {'icon': Icons.workspace_premium_outlined, 'label': 'Top Brands'},
    {'icon': Icons.support_agent_outlined, 'label': '24/7 Support'},
    {'icon': Icons.local_offer_rounded, 'label': 'Best Prices'},
  ];

  static const double _chipWidth = 130.0;
  double get _setWidth => _badges.length * _chipWidth;

  @override
  void initState() {
    super.initState();
    final durationMs = (_setWidth / 60 * 1000).round();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = _controller.value * _setWidth;
            return Stack(
              children: [
                Positioned(
                  left: -offset,
                  child: _BadgeStrip(badges: _badges, chipWidth: _chipWidth),
                ),
                Positioned(
                  left: _setWidth - offset,
                  child: _BadgeStrip(badges: _badges, chipWidth: _chipWidth),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  final List<Map<String, Object>> badges;
  final double chipWidth;
  const _BadgeStrip({required this.badges, required this.chipWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          badges.map((b) {
            return SizedBox(
              width: chipWidth,
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(b['icon'] as IconData, color: AppColors.red, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    b['label'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            );
          }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// STUB PAGES (for bottom nav)
// ─────────────────────────────────────────────
const kPrimary = AppColors.primary;
const kOrange = Color(0xFFFF5500);
const kBgLight = Color(0xFFF9F9F9);
const kBorderBlue = AppColors.border;
const kMuted = AppColors.muted;
const kMuted2 = Color(0xFF757575);

class CategoryItem {
  final int id;
  final String name;
  final String iconAsset;

  const CategoryItem({
    required this.id,
    required this.name,
    this.iconAsset = '',
  });
}

class CategoriesPage extends StatefulWidget {
  final String? initialCategory;
  final bool showBottomNav;
  const CategoriesPage({
    super.key,
    this.initialCategory,
    this.showBottomNav = false,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  static const _cityKey = 'saved_city';
  static const _countryKey = 'saved_country';

  final ScrollController _categoryScrollController = ScrollController();
  final Map<int, int> _categoryCounts = {};
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  List<CategoryItem> _categories = [];
  int _selectedIndex = 0;
  int? _selectedCatId;
  String _selectedCatName = '';
  List<ProductModel> _products = [];
  bool _catsLoading = true;
  bool _prodsLoading = false;
  bool _isListening = false;
  String _selectedCity = 'San Antonio';
  String _selectedCountry = 'United States';

  @override
  void dispose() {
    _speechToText.stop();
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _loadCategories();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_cityKey);
    final country = prefs.getString(_countryKey);

    if (city != null && country != null && city.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedCity = city;
        _selectedCountry = country;
      });
    }
  }

  Future<void> _loadCategories() async {
    final cats = await ProductService.fetchCategories();
    if (!mounted) return;
    final items =
        cats
            .map(
              (c) => CategoryItem(
                id: c['id'] as int,
                name: c['name'] as String? ?? '',
                iconAsset: _categoryLogos[c['name'] as String? ?? ''] ?? '',
              ),
            )
            .toList();

    int initialIndex = 0;
    if (widget.initialCategory != null) {
      final idx = items.indexWhere((c) => c.name == widget.initialCategory);
      if (idx >= 0) initialIndex = idx;
    }

    setState(() {
      _categories = items;
      _selectedIndex = initialIndex;
      _catsLoading = false;
      if (_categories.isNotEmpty) {
        final selected = _categories[_selectedIndex];
        _selectedCatId = selected.id;
        _selectedCatName = selected.name;
      }
    });
    if (_selectedCatId != null) _loadProducts(_selectedCatId!);
  }

  Future<void> _loadProducts(int catId) async {
    setState(() => _prodsLoading = true);
    final prods = await ProductService.fetchProducts(
      categoryId: catId,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      _products = prods;
      _prodsLoading = false;
      _categoryCounts[catId] = prods.length;
    });
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }

  void _openWishlist() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WishlistPage()));
  }

  void _selectIndex(int index) {
    if (index == _selectedIndex) return;
    final selected = _categories[index];
    setState(() {
      _selectedIndex = index;
      _selectedCatId = selected.id;
      _selectedCatName = selected.name;
      _products = [];
    });
    _loadProducts(selected.id);
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

        if (result.finalResult) {
          setState(() {
            _isListening = false;
          });
          _showVoiceMessage('Searching for "$recognizedText"');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SearchResultsPage(query: recognizedText),
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final sidebarWidth =
        isTablet
            ? 175.0
            : size.width < 380
            ? 110.0
            : 130.0;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar:
          widget.showBottomNav
              ? _BottomNavBar(
                currentIndex: 1,
                onSelectPage: (pageIndex) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => MainShell(initialIndex: pageIndex),
                    ),
                    (route) => false,
                  );
                },
              )
              : null,
      body: SafeArea(
        child:
            _catsLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopHeader(
                      isTablet: isTablet,
                      onVoiceTap: _onVoiceTap,
                      onNotificationsTap: _openNotifications,
                      onWishlistTap: _openWishlist,
                      city: _selectedCity,
                      country: _selectedCountry,
                      onLocationTap: _loadSavedLocation,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 20,
                        top: isTablet ? 20 : 14,
                        bottom: isTablet ? 14 : 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 22 : 20,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Browse by department',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: isTablet ? 15 : 14,
                              color: kMuted2,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CategorySidebar(
                            width: sidebarWidth,
                            categories: _categories,
                            selectedIndex: _selectedIndex,
                            categoryCounts: _categoryCounts,
                            scrollController: _categoryScrollController,
                            onSelect: _selectIndex,
                          ),
                          Expanded(
                            child: Container(
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedCatName.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        4,
                                      ),
                                      child: Text(
                                        _selectedCatName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child:
                                        _prodsLoading
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : _products.isEmpty
                                            ? const Center(
                                              child: Text(
                                                'No products found',
                                                style: TextStyle(
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            )
                                            : LayoutBuilder(
                                              builder: (context, constraints) {
                                                final w = constraints.maxWidth;
                                                final crossAxisCount =
                                                    w >= 1100
                                                        ? 4
                                                        : w >= 850
                                                        ? 3
                                                        : w >= 600
                                                        ? 2
                                                        : 2;
                                                final tileWidth =
                                                    (w -
                                                        24 -
                                                        ((crossAxisCount - 1) *
                                                            12)) /
                                                    crossAxisCount;
                                                final mainAxisExtent =
                                                    (tileWidth * 1.25).clamp(
                                                      238.0,
                                                      258.0,
                                                    );
                                                return GridView.builder(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount:
                                                            crossAxisCount,
                                                        crossAxisSpacing: 12,
                                                        mainAxisSpacing: 12,
                                                        mainAxisExtent:
                                                            mainAxisExtent,
                                                      ),
                                                  itemCount: _products.length,
                                                  itemBuilder:
                                                      (ctx, i) => _ProductCard(
                                                        product: _products[i],
                                                        sourceTabIndex: 1,
                                                      ),
                                                );
                                              },
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
                ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY PAGE UI
// ─────────────────────────────────────────────
class _TopHeader extends StatelessWidget {
  final bool isTablet;
  final VoidCallback onVoiceTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onWishlistTap;
  final String city;
  final String country;
  final VoidCallback onLocationTap;

  const _TopHeader({
    required this.isTablet,
    required this.onVoiceTap,
    required this.onNotificationsTap,
    required this.onWishlistTap,
    required this.city,
    required this.country,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    const hPad = 20.0;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(hPad, 10, hPad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isTablet ? 110 : 94,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Image.asset(
                      'assets/d-lab-logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onLocationTap,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$city, $country',
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
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
              Row(
                children: [
                  _IconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: onNotificationsTap,
                  ),
                  SizedBox(width: 10),
                  _IconButton(
                    icon: Icons.favorite_border_rounded,
                    onTap: onWishlistTap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: kBgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorderBlue),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: kPrimary, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Search products...',
                      style: TextStyle(color: Color(0xFF9DB2CE), fontSize: 15),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(21.5),
                    onTap: onVoiceTap,
                    child: Container(
                      width: 43,
                      height: 43,
                      padding: const EdgeInsets.fromLTRB(12, 12, 11, 11),
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorderBlue),
                        borderRadius: BorderRadius.circular(21.5),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/icons/mic.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: kBorderBlue),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final double width;
  final List<CategoryItem> categories;
  final int selectedIndex;
  final Map<int, int> categoryCounts;
  final ScrollController scrollController;
  final ValueChanged<int> onSelect;

  const _CategorySidebar({
    required this.width,
    required this.categories,
    required this.selectedIndex,
    required this.categoryCounts,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: kBgLight)),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: RawScrollbar(
              controller: scrollController,
              thumbColor: kMuted2,
              radius: const Radius.circular(20),
              thickness: 8,
              trackColor: Colors.white,
              trackVisibility: true,
              thumbVisibility: true,
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: categories.length,
                itemBuilder:
                    (ctx, i) => _CategoryTile(
                      item: categories[i],
                      itemCount: categoryCounts[categories[i].id],
                      isSelected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryItem item;
  final int? itemCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.item,
    required this.itemCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
        width: double.infinity,
        height: 114,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          border:
              isSelected
                  ? const Border(left: BorderSide(color: kPrimary, width: 2.5))
                  : null,
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(-2, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(2, 4),
                    ),
                  ]
                  : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected
                        ? kPrimary.withValues(alpha: 0.10)
                        : Colors.grey.shade200,
              ),
              child: ClipOval(child: _CategoryIcon(assetPath: item.iconAsset)),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                height: 1.2,
                color: kPrimary,
              ),
            ),
            if (itemCount != null)
              Text(
                '$itemCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  color: kPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String assetPath;
  const _CategoryIcon({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    if (assetPath.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, size: 20, color: kMuted),
      );
    }
    return Image.asset(
      assetPath,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => const Center(
            child: Icon(Icons.image_outlined, size: 20, color: kMuted),
          ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const Color _darkText = Color(0xFF0B1527);
  static const Color _muted = Color(0xFF6B7280);
  static const String _imgProxyBase = 'http://app.dezign-lab.com:3000';

  final CartService _cartService = CartService.instance;

  List<CartProduct> _cartItems = <CartProduct>[];
  List<CartProduct> _savedItems = <CartProduct>[];
  List<ProductModel> _recommendations = <ProductModel>[];
  Set<int> _selectedItemIds = <int>{};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRecommendations();
  }

  String _imgUrl(String url) {
    if (!kIsWeb) {
      return url;
    }
    return '$_imgProxyBase/api/image-proxy?url=${Uri.encodeComponent(url)}';
  }

  double _itemDisplayPrice(CartProduct item) {
    return item.salePrice ?? item.regularPrice;
  }

  Future<void> _loadData() async {
    await _cartService.initialize();
    final cart = await _cartService.getAll();
    final saved = await _cartService.getSavedForLater();
    if (!mounted) {
      return;
    }

    setState(() {
      _cartItems = cart;
      _savedItems = saved;
      final cartIds = cart.map((item) => item.id).toSet();
      _selectedItemIds = _selectedItemIds.where(cartIds.contains).toSet();
      if (_selectedItemIds.isEmpty) {
        _selectedItemIds = cartIds;
      }
      _loading = false;
    });
  }

  Future<void> _loadRecommendations() async {
    final products = await ProductService.fetchProducts(limit: 8, offset: 24);
    if (!mounted) {
      return;
    }

    final excluded = {
      ..._cartItems.map((e) => e.id),
      ..._savedItems.map((e) => e.id),
    };

    setState(() {
      _recommendations =
          products.where((p) => !excluded.contains(p.id)).toList();
    });
  }

  Future<void> _increaseQty(CartProduct item) async {
    await _cartService.setQuantity(item.id, item.quantity + 1);
    await _loadData();
  }

  Future<void> _decreaseQty(CartProduct item) async {
    if (item.quantity <= 1) {
      await _cartService.remove(item.id);
    } else {
      await _cartService.setQuantity(item.id, item.quantity - 1);
    }
    await _loadData();
  }

  Future<void> _deleteItem(CartProduct item) async {
    await _cartService.remove(item.id);
    await _loadData();
  }

  Future<void> _saveForLater(CartProduct item) async {
    await _cartService.saveForLater(item.id);
    await _loadData();
  }

  Future<void> _moveSavedToCart(CartProduct item) async {
    await _cartService.moveSavedToCart(item.id);
    await _loadData();
  }

  Future<void> _deleteSaved(CartProduct item) async {
    await _cartService.removeSaved(item.id);
    await _loadData();
  }

  Future<void> _addRecommendation(ProductModel product) async {
    await _cartService.addOrIncrement(
      CartProduct(
        id: product.id,
        name: product.name,
        images: product.images,
        imageUrl:
            product.images.isNotEmpty ? product.images.first : product.imageUrl,
        salePrice: product.salePrice,
        regularPrice: product.regularPrice,
        quantity: 1,
        addedAt: DateTime.now(),
      ),
    );
    await _loadData();
  }

  Future<void> _removeSelected() async {
    for (final id in _selectedItemIds.toList()) {
      await _cartService.remove(id);
    }
    await _loadData();
  }

  double get _selectedItemTotal {
    return _cartItems
        .where((item) => _selectedItemIds.contains(item.id))
        .fold<double>(
          0,
          (sum, item) => sum + (item.regularPrice * item.quantity),
        );
  }

  double get _selectedDiscount {
    return _cartItems
        .where((item) => _selectedItemIds.contains(item.id))
        .fold<double>(
          0,
          (sum, item) =>
              sum +
              (((item.regularPrice - (item.salePrice ?? item.regularPrice)) *
                      item.quantity)
                  .clamp(0, double.infinity)),
        );
  }

  double get _grandTotal => _selectedItemTotal - _selectedDiscount;

  String _price(double value) => '₹${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cartItems.isEmpty) {
      return const ResponsiveEmptyCartScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed:
              () =>
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MainShell(initialIndex: 0),
                    ),
                    (route) => false,
                  ),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Cart',
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CartOrderSummaryCard(
                    itemTotal: _selectedItemTotal,
                    discount: _selectedDiscount,
                    grandTotal: _grandTotal,
                    onCheckout: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items (${_cartItems.length.toString().padLeft(2, '0')})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: _muted),
                        onSelected: (value) async {
                          if (value == 'select_all') {
                            setState(() {
                              _selectedItemIds =
                                  _cartItems.map((item) => item.id).toSet();
                            });
                          } else if (value == 'clear_selection') {
                            setState(() {
                              _selectedItemIds.clear();
                            });
                          } else if (value == 'remove_selected') {
                            await _removeSelected();
                          }
                        },
                        itemBuilder:
                            (context) => const [
                              PopupMenuItem(
                                value: 'select_all',
                                child: Text('Select all'),
                              ),
                              PopupMenuItem(
                                value: 'clear_selection',
                                child: Text('Clear selection'),
                              ),
                              PopupMenuItem(
                                value: 'remove_selected',
                                child: Text('Delete selected'),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return _CartItemCard(
                      item: item,
                      selected: _selectedItemIds.contains(item.id),
                      imageUrlBuilder: _imgUrl,
                      priceText: _price(_itemDisplayPrice(item)),
                      onToggleSelected: () {
                        setState(() {
                          if (_selectedItemIds.contains(item.id)) {
                            _selectedItemIds.remove(item.id);
                          } else {
                            _selectedItemIds.add(item.id);
                          }
                        });
                      },
                      onIncrease: () => _increaseQty(item),
                      onDecrease: () => _decreaseQty(item),
                      onSaveForLater: () => _saveForLater(item),
                      onDelete: () => _deleteItem(item),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _CartOffersBanner(),
                ),
                if (_savedItems.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Saved for later (${_savedItems.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _savedItems.length,
                    itemBuilder: (context, index) {
                      final item = _savedItems[index];
                      return _SavedForLaterCard(
                        item: item,
                        imageUrlBuilder: _imgUrl,
                        priceText: _price(_itemDisplayPrice(item)),
                        onMoveToCart: () => _moveSavedToCart(item),
                        onDelete: () => _deleteSaved(item),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Recommendation Based on Items in your cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 282,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommendations.length,
                          itemBuilder: (context, index) {
                            final product = _recommendations[index];
                            return _CartRecommendationCard(
                              product: product,
                              imageUrlBuilder: _imgUrl,
                              onAddToCart: () => _addRecommendation(product),
                            );
                          },
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
    );
  }
}

class _CartOrderSummaryCard extends StatelessWidget {
  final double itemTotal;
  final double discount;
  final double grandTotal;
  final VoidCallback onCheckout;

  const _CartOrderSummaryCard({
    required this.itemTotal,
    required this.discount,
    required this.grandTotal,
    required this.onCheckout,
  });

  String _price(double value) => '₹${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF6B7280), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shopping Cart',
            style: TextStyle(
              color: Color(0xFF1B4965),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFDADADA), thickness: 0.5),
          const SizedBox(height: 12),
          _summaryRow('Item Total', _price(itemTotal), false),
          const SizedBox(height: 8),
          _summaryRow('Discount', '-${_price(discount)}', false),
          const SizedBox(height: 8),
          _summaryRow('Delivery Fee', 'Free', false),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFDADADA), thickness: 0.5),
          const SizedBox(height: 12),
          _summaryRow('Grand Total', _price(grandTotal), true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4965),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onCheckout,
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF0B1527),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            fontSize: isBold ? 20 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF1B4965),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 20 : 14,
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartProduct item;
  final bool selected;
  final String Function(String) imageUrlBuilder;
  final String priceText;
  final VoidCallback onToggleSelected;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onSaveForLater;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.selected,
    required this.imageUrlBuilder,
    required this.priceText,
    required this.onToggleSelected,
    required this.onIncrease,
    required this.onDecrease,
    required this.onSaveForLater,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final displayImage =
        item.images.isNotEmpty ? item.images.first : (item.imageUrl ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 40),
            child: InkWell(
              onTap: onToggleSelected,
              child: Icon(
                selected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank_rounded,
                color: const Color(0xFF1B4965),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 7.3,
                    offset: const Offset(0, 0),
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            displayImage.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrlBuilder(displayImage),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.laptop_mac,
                                          color: Colors.grey,
                                        ),
                                  ),
                                )
                                : const Icon(
                                  Icons.laptop_mac,
                                  color: Colors.grey,
                                ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'FREE Delivery Tue 7, Apr',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'IN STOCK',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF26A541),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              priceText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF6B7280)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: onDecrease,
                              child: const Icon(
                                Icons.remove,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: onIncrease,
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Color(0xFF1B4965),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: onSaveForLater,
                            child: const Text(
                              'Save for later',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: onDelete,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFF1B4965),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedForLaterCard extends StatelessWidget {
  final CartProduct item;
  final String Function(String) imageUrlBuilder;
  final String priceText;
  final VoidCallback onMoveToCart;
  final VoidCallback onDelete;

  const _SavedForLaterCard({
    required this.item,
    required this.imageUrlBuilder,
    required this.priceText,
    required this.onMoveToCart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final displayImage =
        item.images.isNotEmpty ? item.images.first : (item.imageUrl ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 7.3,
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  displayImage.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrlBuilder(displayImage),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Icons.laptop_mac,
                                color: Colors.grey,
                              ),
                        ),
                      )
                      : const Icon(Icons.laptop_mac, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: onMoveToCart,
                        child: const Text(
                          'Move to cart',
                          style: TextStyle(
                            color: Color(0xFF1B4965),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFF1B4965),
                          size: 20,
                        ),
                      ),
                    ],
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

class _CartOffersBanner extends StatelessWidget {
  const _CartOffersBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(139, 237, 160, 0.2),
        border: Border.all(color: const Color(0xFF26A541)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Save Extra With Offers',
            style: TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
          Row(
            children: [
              Text(
                'See Offers',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_right,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartRecommendationCard extends StatelessWidget {
  final ProductModel product;
  final String Function(String) imageUrlBuilder;
  final VoidCallback onAddToCart;

  const _CartRecommendationCard({
    required this.product,
    required this.imageUrlBuilder,
    required this.onAddToCart,
  });

  String _price(double value) => '₹${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final hasSale =
        product.salePrice != null && product.salePrice! < product.regularPrice;
    final displayPrice = hasSale ? product.salePrice! : product.regularPrice;
    final discount =
        hasSale
            ? ((1 - (displayPrice / product.regularPrice)) * 100).round().clamp(
              0,
              99,
            )
            : 0;
    final displayImage =
        product.images.isNotEmpty
            ? product.images.first
            : (product.imageUrl ?? '');

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12, left: 10, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF2F2F2)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5),
                ),
                child:
                    displayImage.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            imageUrlBuilder(displayImage),
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.laptop,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                          ),
                        )
                        : const Icon(
                          Icons.laptop,
                          size: 50,
                          color: Colors.grey,
                        ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5500),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        '4.6',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.star, size: 10, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            hasSale
                ? '${_price(displayPrice)} ${_price(product.regularPrice)} $discount% off'
                : _price(displayPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4965),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onAddToCart,
              child: const Text(
                'Add to Cart',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive Empty Cart Screen
/// This screen adapts to different screen sizes while maintaining the design
class ResponsiveEmptyCartScreen extends StatelessWidget {
  const ResponsiveEmptyCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const Spacer(flex: 1),
                      _buildEmptyCartIllustration(
                        size: size,
                        isSmallScreen: isSmallScreen,
                        isLargeScreen: isLargeScreen,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      _buildEmptyMessage(
                        isSmallScreen: isSmallScreen,
                        isLargeScreen: isLargeScreen,
                      ),
                      const Spacer(flex: 2),
                      _buildCheckoutButton(
                        context,
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap:
                () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const MainShell(initialIndex: 0),
                  ),
                  (route) => false,
                ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF1B4965),
                  size: 20,
                ),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Cart',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B1527),
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyCartIllustration({
    required Size size,
    required bool isSmallScreen,
    required bool isLargeScreen,
  }) {
    double imageWidth = 284;
    double imageHeight = 203;

    if (isSmallScreen) {
      imageWidth = size.width * 0.7;
      imageHeight = imageWidth * (203 / 284);
    } else if (isLargeScreen) {
      imageWidth = 320;
      imageHeight = 229;
    }

    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: Image.asset(
        'assets/images/emptycart.png',
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: imageWidth,
            height: imageHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Color(0xFF1B4965),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyMessage({
    required bool isSmallScreen,
    required bool isLargeScreen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Your cart is empty',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: isSmallScreen ? 20 : (isLargeScreen ? 28 : 24),
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCheckoutButton(
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: isSmallScreen ? 44 : 48,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your cart is empty. Add items to checkout.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4965),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            disabledBackgroundColor: const Color(0xFF1B4965).withOpacity(0.5),
          ),
          child: Text(
            'Proceed to checkout',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class CartColors {
  static const Color primary = Color(0xFF1B4965);
  static const Color fontColor = Color(0xFF0B1527);
  static const Color background = Color(0xFFF5F5FF);
  static const Color white = Color(0xFFFFFFFF);
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
