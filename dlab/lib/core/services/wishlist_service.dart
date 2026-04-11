import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistProduct {
  const WishlistProduct({
    required this.id,
    required this.name,
    required this.images,
    required this.imageUrl,
    required this.salePrice,
    required this.regularPrice,
    required this.categoryId,
    required this.shortDescription,
    required this.description,
    required this.isVariable,
    required this.length,
    required this.width,
    required this.height,
    required this.addedAt,
  });

  final int id;
  final String name;
  final List<String> images;
  final String? imageUrl;
  final double? salePrice;
  final double regularPrice;
  final int? categoryId;
  final String? shortDescription;
  final String? description;
  final bool isVariable;
  final String? length;
  final String? width;
  final String? height;
  final DateTime addedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'images': images,
      'imageUrl': imageUrl,
      'salePrice': salePrice,
      'regularPrice': regularPrice,
      'categoryId': categoryId,
      'shortDescription': shortDescription,
      'description': description,
      'isVariable': isVariable,
      'length': length,
      'width': width,
      'height': height,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory WishlistProduct.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images'];
    return WishlistProduct(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      images: rawImages is List ? rawImages.whereType<String>().toList() : const [],
      imageUrl: map['imageUrl'] as String?,
      salePrice: (map['salePrice'] as num?)?.toDouble(),
      regularPrice: (map['regularPrice'] as num?)?.toDouble() ?? 0,
      categoryId: (map['categoryId'] as num?)?.toInt(),
      shortDescription: map['shortDescription'] as String?,
      description: map['description'] as String?,
      isVariable: map['isVariable'] as bool? ?? false,
      length: map['length'] as String?,
      width: map['width'] as String?,
      height: map['height'] as String?,
      addedAt: DateTime.tryParse(map['addedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class WishlistService {
  WishlistService._();

  static const _prefsKey = 'wishlist_products_v1';
  static final WishlistService instance = WishlistService._();

  final ValueNotifier<Set<int>> likedIds = ValueNotifier<Set<int>>(<int>{});

  final Map<int, WishlistProduct> _cache = <int, WishlistProduct>{};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_prefsKey) ?? const <String>[];

    _cache
      ..clear()
      ..addEntries(
        rawList
            .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
            .map(WishlistProduct.fromMap)
            .where((item) => item.id > 0)
            .map((item) => MapEntry(item.id, item)),
      );

    likedIds.value = _cache.keys.toSet();
    _initialized = true;
  }

  Future<bool> isLiked(int productId) async {
    await initialize();
    return _cache.containsKey(productId);
  }

  Future<void> toggle(WishlistProduct product) async {
    await initialize();

    if (_cache.containsKey(product.id)) {
      _cache.remove(product.id);
    } else {
      _cache[product.id] = product;
    }

    await _persist();
  }

  Future<void> remove(int productId) async {
    await initialize();
    if (_cache.remove(productId) != null) {
      await _persist();
    }
  }

  Future<List<WishlistProduct>> getAll() async {
    await initialize();
    final items = _cache.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _cache.values.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_prefsKey, encoded);
    likedIds.value = _cache.keys.toSet();
  }
}
