import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'dlabs_home_page.dart';
import 'product_details_page.dart';
import 'search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _recentSearchesKey = 'recentSearches';
  static const _recentSearchesMetaKey = 'recentSearchesMeta';
  static const _imgProxyBase = 'http://app.dezign-lab.com:3000';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  List<ProductModel> _allProducts = <ProductModel>[];
  List<ProductModel> _searchSuggestions = <ProductModel>[];
  List<ProductModel> _relatedProducts = <ProductModel>[];
  List<_RecentSearchItem> _recentSearches = <_RecentSearchItem>[];

  bool _isListening = false;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _imgUrl(String url) {
    if (!kIsWeb) {
      return url;
    }
    return '$_imgProxyBase/api/image-proxy?url=${Uri.encodeComponent(url)}';
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.fetchProducts(
        limit: 120,
        offset: 0,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _allProducts = products;
        _isLoadingProducts = false;
      });

      if (_searchController.text.trim().isNotEmpty) {
        _applyLiveSearch(_searchController.text);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _allProducts = <ProductModel>[];
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedRecent =
        prefs.getStringList(_recentSearchesMetaKey) ?? <String>[];

    List<_RecentSearchItem> decoded = encodedRecent
        .map((entry) {
          try {
            final dynamic data = jsonDecode(entry);
            if (data is Map<String, dynamic>) {
              return _RecentSearchItem.fromJson(data);
            }
          } catch (_) {}
          return null;
        })
        .whereType<_RecentSearchItem>()
        .where((item) => item.query.trim().isNotEmpty)
        .toList(growable: false);

    if (decoded.isEmpty) {
      final List<String> fallback =
          prefs.getStringList(_recentSearchesKey) ?? <String>[];
      decoded = fallback
          .where((query) => query.trim().isNotEmpty)
          .map((query) => _RecentSearchItem(query: query.trim()))
          .toList(growable: false);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _recentSearches = decoded;
    });
  }

  Future<void> _persistRecentSearches(SharedPreferences prefs) async {
    await prefs.setStringList(
      _recentSearchesMetaKey,
      _recentSearches
          .map((item) => jsonEncode(item.toJson()))
          .toList(growable: false),
    );
    await prefs.setStringList(
      _recentSearchesKey,
      _recentSearches.map((item) => item.query).toList(growable: false),
    );
  }

  String? _resolveRecentSearchImage(String query) {
    final List<String> tokens = _tokenizeQuery(query);
    if (tokens.isEmpty) {
      return null;
    }

    if (_searchSuggestions.isNotEmpty) {
      return _productImage(_searchSuggestions.first);
    }

    final ProductModel? bestMatch = _allProducts
        .where((product) => _matchesProduct(product, tokens))
        .cast<ProductModel?>()
        .firstWhere((_) => true, orElse: () => null);

    if (bestMatch == null) {
      return null;
    }

    return _productImage(bestMatch);
  }

  Future<void> _saveRecentSearch(String query, {String? imageUrl}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final List<_RecentSearchItem> updated = List<_RecentSearchItem>.from(
      _recentSearches,
    )..removeWhere(
      (element) => element.query.toLowerCase() == trimmed.toLowerCase(),
    );

    updated.insert(0, _RecentSearchItem(query: trimmed, imageUrl: imageUrl));
    if (updated.length > 5) {
      updated.removeRange(5, updated.length);
    }

    _recentSearches = updated;
    if (mounted) {
      setState(() {});
    }

    await _persistRecentSearches(prefs);
  }

  Future<void> _removeRecentSearch(String query) async {
    final String normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }

    final List<_RecentSearchItem> updated = List<_RecentSearchItem>.from(
      _recentSearches,
    )..removeWhere((item) => item.query.trim().toLowerCase() == normalized);

    _recentSearches = updated;
    if (mounted) {
      setState(() {});
    }

    final prefs = await SharedPreferences.getInstance();
    await _persistRecentSearches(prefs);
  }

  Future<void> _clearAllRecentSearches() async {
    _recentSearches = <_RecentSearchItem>[];
    if (mounted) {
      setState(() {});
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    await prefs.remove(_recentSearchesMetaKey);
  }

  List<String> _tokenizeQuery(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  bool _containsAllTokens(String text, List<String> tokens) {
    final normalized = text.toLowerCase();
    return tokens.every(normalized.contains);
  }

  bool _matchesProduct(ProductModel product, List<String> tokens) {
    final searchableText = [
      product.name,
      product.shortDescription ?? '',
      product.description ?? '',
    ].join(' ');

    return _containsAllTokens(searchableText, tokens);
  }

  double _searchScore(ProductModel product, List<String> tokens) {
    final name = product.name.toLowerCase();
    final joinedQuery = tokens.join(' ');
    double score = 0;

    if (name.startsWith(joinedQuery)) {
      score += 100;
    }
    if (name.contains(joinedQuery)) {
      score += 60;
    }

    for (final token in tokens) {
      if (name.startsWith(token)) {
        score += 20;
      }
      if (name.contains(token)) {
        score += 10;
      }
    }

    return score;
  }

  void _applyLiveSearch(String queryText) {
    final tokens = _tokenizeQuery(queryText);

    if (tokens.isEmpty) {
      setState(() {
        _searchSuggestions = <ProductModel>[];
        _relatedProducts = <ProductModel>[];
      });
      return;
    }

    final matched =
        _allProducts
            .where((product) => _matchesProduct(product, tokens))
            .toList();

    matched.sort((a, b) {
      final scoreDiff = _searchScore(
        b,
        tokens,
      ).compareTo(_searchScore(a, tokens));
      if (scoreDiff != 0) {
        return scoreDiff;
      }
      return b.id.compareTo(a.id);
    });

    setState(() {
      _searchSuggestions = matched.take(5).toList(growable: false);
      _relatedProducts = matched.take(6).toList(growable: false);
    });
  }

  String? _productImage(ProductModel product) {
    if (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty) {
      return product.imageUrl;
    }
    if (product.images.isNotEmpty && product.images.first.trim().isNotEmpty) {
      return product.images.first;
    }
    return null;
  }

  void _selectSuggestion(ProductModel product) {
    _searchController.text = product.name;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _applyLiveSearch(product.name);
  }

  void _openProductDetails(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(product: product, sourceTabIndex: 0),
      ),
    );
  }

  void _onSearchChanged() {
    _applyLiveSearch(_searchController.text);
  }

  void _handleSearchSubmit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _saveRecentSearch(trimmed, imageUrl: _resolveRecentSearchImage(trimmed));
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchResultsPage(query: trimmed)),
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
          _handleSearchSubmit(recognizedText);
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

  @override
  Widget build(BuildContext context) {
    final searchText = _searchController.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF1B4965),
                      ),
                    ),
                  ),
                  Expanded(child: _buildSearchBar()),
                ],
              ),
              const SizedBox(height: 12),
              if (searchText.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildRecommendationsBox(),
                        _buildRelatedProductsSection(),
                      ],
                    ),
                  ),
                )
              else if (_recentSearches.isNotEmpty)
                Expanded(child: _buildRecentSearchesBox()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCAE9FF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSearchSubmit,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Color(0xFF9DB2CE), fontSize: 15),
                border: InputBorder.none,
              ),
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
                border: Border.all(color: const Color(0xFFCAE9FF)),
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
    );
  }

  Widget _buildRecommendationsBox() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: const Color(0xFFCAE9FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          _isLoadingProducts
              ? const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading products...',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
              : _searchSuggestions.isEmpty
              ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No products found',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              )
              : ListView.separated(
                itemCount: _searchSuggestions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder:
                    (_, __) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Color(0xFFCAE9FF),
                    ),
                itemBuilder: (context, index) {
                  final product = _searchSuggestions[index];
                  final imageUrl = _productImage(product);

                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEDF2F7)),
                      ),
                      child:
                          imageUrl == null
                              ? const Icon(
                                Icons.devices_other_rounded,
                                size: 20,
                                color: Color(0xFF9DB2CE),
                              )
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  _imgUrl(imageUrl),
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (_, __, ___) => const Icon(
                                        Icons.devices_other_rounded,
                                        size: 20,
                                        color: Color(0xFF9DB2CE),
                                      ),
                                ),
                              ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    onTap: () => _selectSuggestion(product),
                  );
                },
              ),
    );
  }

  Widget _buildRelatedProductsSection() {
    if (_isLoadingProducts) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Related Products',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          if (_relatedProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'No related products found.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 10.0;
                final cardWidth = (constraints.maxWidth - gap) / 2;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children:
                      _relatedProducts
                          .map(
                            (product) => SizedBox(
                              width: cardWidth,
                              child: _InlineRelatedProductCard(
                                product: product,
                                imageUrlBuilder: _imgUrl,
                                onTap: () => _openProductDetails(product),
                              ),
                            ),
                          )
                          .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesBox() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: const Color(0xFFCAE9FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _recentSearches.length,
              separatorBuilder:
                  (_, __) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFCAE9FF),
                  ),
              itemBuilder: (context, index) {
                final item = _recentSearches[index];
                final query = item.query;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _searchController.text = query;
                            _searchController
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _searchController.text.length,
                              ),
                            );
                            _handleSearchSubmit(query);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFEDF2F7),
                                    ),
                                  ),
                                  child:
                                      item.imageUrl == null
                                          ? const Icon(
                                            Icons.devices_other_rounded,
                                            size: 20,
                                            color: Color(0xFF9DB2CE),
                                          )
                                          : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.network(
                                              _imgUrl(item.imageUrl!),
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (_, __, ___) => const Icon(
                                                    Icons.devices_other_rounded,
                                                    size: 20,
                                                    color: Color(0xFF9DB2CE),
                                                  ),
                                            ),
                                          ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    query,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeRecentSearch(query),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF1B4965),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clearAllRecentSearches,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineRelatedProductCard extends StatelessWidget {
  final ProductModel product;
  final String Function(String url) imageUrlBuilder;
  final VoidCallback onTap;

  const _InlineRelatedProductCard({
    required this.product,
    required this.imageUrlBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSale =
        product.salePrice != null && product.salePrice! < product.regularPrice;
    final double displayPrice =
        hasSale ? product.salePrice! : product.regularPrice;
    final String? imageUrl =
        product.imageUrl ??
        (product.images.isNotEmpty ? product.images.first : null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF2F2F2)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 95,
              width: double.infinity,
              child:
                  imageUrl == null
                      ? const Center(
                        child: Icon(
                          Icons.devices_other_rounded,
                          color: Color(0xFFCAE9FF),
                          size: 40,
                        ),
                      )
                      : Image.network(
                        imageUrlBuilder(imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => const Center(
                              child: Icon(
                                Icons.devices_other_rounded,
                                color: Color(0xFFCAE9FF),
                                size: 40,
                              ),
                            ),
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${displayPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            if (hasSale)
              Text(
                '\$${product.regularPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF757575),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF1B4965),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'View Product',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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

class _RecentSearchItem {
  final String query;
  final String? imageUrl;

  const _RecentSearchItem({required this.query, this.imageUrl});

  factory _RecentSearchItem.fromJson(Map<String, dynamic> json) {
    return _RecentSearchItem(
      query: (json['query'] ?? '').toString(),
      imageUrl:
          (json['imageUrl'] ?? '').toString().trim().isEmpty
              ? null
              : json['imageUrl'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'query': query, 'imageUrl': imageUrl};
  }
}
