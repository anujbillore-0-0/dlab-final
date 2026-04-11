import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProduct {
  const CartProduct({
    required this.id,
    required this.name,
    required this.images,
    required this.imageUrl,
    required this.salePrice,
    required this.regularPrice,
    required this.quantity,
    required this.addedAt,
  });

  final int id;
  final String name;
  final List<String> images;
  final String? imageUrl;
  final double? salePrice;
  final double regularPrice;
  final int quantity;
  final DateTime addedAt;

  CartProduct copyWith({
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartProduct(
      id: id,
      name: name,
      images: images,
      imageUrl: imageUrl,
      salePrice: salePrice,
      regularPrice: regularPrice,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'images': images,
      'imageUrl': imageUrl,
      'salePrice': salePrice,
      'regularPrice': regularPrice,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartProduct.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images'];
    return CartProduct(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      images: rawImages is List ? rawImages.whereType<String>().toList() : const [],
      imageUrl: map['imageUrl'] as String?,
      salePrice: (map['salePrice'] as num?)?.toDouble(),
      regularPrice: (map['regularPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      addedAt: DateTime.tryParse(map['addedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class CartService {
  CartService._();

  static const _prefsKey = 'cart_products_v1';
  static const _savedPrefsKey = 'saved_for_later_products_v1';
  static final CartService instance = CartService._();

  final ValueNotifier<int> itemCount = ValueNotifier<int>(0);
  final Map<int, CartProduct> _cache = <int, CartProduct>{};
  final Map<int, CartProduct> _savedCache = <int, CartProduct>{};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_prefsKey) ?? const <String>[];
    final rawSavedList =
      prefs.getStringList(_savedPrefsKey) ?? const <String>[];

    _cache
      ..clear()
      ..addEntries(
        rawList
            .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
            .map(CartProduct.fromMap)
            .where((item) => item.id > 0 && item.quantity > 0)
            .map((item) => MapEntry(item.id, item)),
      );

            _savedCache
          ..clear()
          ..addEntries(
            rawSavedList
            .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
            .map(CartProduct.fromMap)
            .where((item) => item.id > 0)
            .map((item) => MapEntry(item.id, item)),
          );

    _initialized = true;
    _notifyCount();
  }

  Future<void> addOrIncrement(CartProduct product, {int by = 1}) async {
    await initialize();
    final current = _cache[product.id];
    if (current == null) {
      _cache[product.id] = product.copyWith(
        quantity: by,
        addedAt: DateTime.now(),
      );
    } else {
      _cache[product.id] = current.copyWith(
        quantity: current.quantity + by,
        addedAt: DateTime.now(),
      );
    }
    await _persist();
  }

  Future<void> setQuantity(int productId, int quantity) async {
    await initialize();
    final existing = _cache[productId];
    if (existing == null) {
      return;
    }
    if (quantity <= 0) {
      _cache.remove(productId);
    } else {
      _cache[productId] = existing.copyWith(quantity: quantity);
    }
    await _persist();
  }

  Future<void> remove(int productId) async {
    await initialize();
    if (_cache.remove(productId) != null) {
      await _persist();
    }
  }

  Future<void> saveForLater(int productId) async {
    await initialize();
    final item = _cache.remove(productId);
    if (item == null) {
      return;
    }
    _savedCache[productId] = item.copyWith(addedAt: DateTime.now());
    await _persist();
  }

  Future<void> moveSavedToCart(int productId) async {
    await initialize();
    final item = _savedCache.remove(productId);
    if (item == null) {
      return;
    }
    final current = _cache[productId];
    if (current == null) {
      _cache[productId] = item.copyWith(addedAt: DateTime.now());
    } else {
      _cache[productId] = current.copyWith(
        quantity: current.quantity + item.quantity,
        addedAt: DateTime.now(),
      );
    }
    await _persist();
  }

  Future<void> removeSaved(int productId) async {
    await initialize();
    if (_savedCache.remove(productId) != null) {
      await _persist();
    }
  }

  Future<List<CartProduct>> getAll() async {
    await initialize();
    final items = _cache.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  Map<int, int> getQuantities() {
    return _cache.map((key, value) => MapEntry(key, value.quantity));
  }

  Future<List<CartProduct>> getSavedForLater() async {
    await initialize();
    final items = _savedCache.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _cache.values.map((item) => jsonEncode(item.toMap())).toList();
    final savedEncoded =
        _savedCache.values.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_prefsKey, encoded);
    await prefs.setStringList(_savedPrefsKey, savedEncoded);
    _notifyCount();
  }

  void _notifyCount() {
    final count = _cache.values.fold<int>(0, (sum, item) => sum + item.quantity);
    itemCount.value = count;
  }
}