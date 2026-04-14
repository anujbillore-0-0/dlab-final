import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilterBottomSheetSelection {
  const FilterBottomSheetSelection({
    required this.popularFilters,
    required this.selectedBrands,
    required this.selectedColor,
    required this.currentPriceRange,
  });

  final Set<String> popularFilters;
  final Set<String> selectedBrands;
  final String selectedColor;
  final RangeValues currentPriceRange;
}

class FilterBottomSheetWidget extends StatefulWidget {
  const FilterBottomSheetWidget({
    super.key,
    this.onApply,
    this.onApplySelection,
    this.initialPopularFilters,
    this.initialSelectedBrands,
    this.initialSelectedColor,
    this.initialPriceRange,
    this.maxPrice = 1500,
  });

  final ValueChanged<Set<String>>? onApply;
  final ValueChanged<FilterBottomSheetSelection>? onApplySelection;
  final Set<String>? initialPopularFilters;
  final Set<String>? initialSelectedBrands;
  final String? initialSelectedColor;
  final RangeValues? initialPriceRange;
  final double maxPrice;

  static Future<void> show(
    BuildContext context, {
    ValueChanged<Set<String>>? onApply,
    ValueChanged<FilterBottomSheetSelection>? onApplySelection,
    Set<String>? initialPopularFilters,
    Set<String>? initialSelectedBrands,
    String? initialSelectedColor,
    RangeValues? initialPriceRange,
    double maxPrice = 1500,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheetWidget(
        onApply: onApply,
        onApplySelection: onApplySelection,
        initialPopularFilters: initialPopularFilters,
        initialSelectedBrands: initialSelectedBrands,
        initialSelectedColor: initialSelectedColor,
        initialPriceRange: initialPriceRange,
        maxPrice: maxPrice,
      ),
    );
  }

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  static const Color _primaryColor = Color(0xFF1B4965);
  static const Color _accentColor = Color(0xFFFF5500);
  static const Color _borderColor = Color(0xFFDADADA);
  static const Color _backgroundColor = Color(0xFFFFFFFF);
  static const Color _darkTextColor = Color(0xFF0B1527);
  static const Color _mutedTextColor = Color(0xFF6B7280);

  static const List<String> _popularFilters = <String>[
    'Best Seller',
    'New Arrivals',
    'On Sale',
    'Free Shipping',
  ];

  static const Map<String, int> _brandOptions = <String, int>{
    'Sony': 156,
    'Bose': 89,
    'Apple': 203,
    'JBL': 67,
  };

  static const Map<String, Color> _colourOptions = <String, Color>{
    'White': Color(0xFFFFFFFF),
    'Black': Color(0xFF000000),
    'Silver': Color(0xFFDBDBDB),
    'Yellow': Color(0xFFFFE500),
    'Blue': Color(0xFF2B729C),
    'Red': Color(0xFFFF383C),
    'Green': Color(0xFF26A541),
    'Pink': Color(0xFFFED6D6),
  };

  late final Set<String> _selectedPopularFilters;

  late final Set<String> selectedBrands;
  late String selectedColor;
  late RangeValues currentPriceRange;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  late final FocusNode _minPriceFocusNode;
  late final FocusNode _maxPriceFocusNode;

  bool _isPriceRangeExpanded = false;
  bool _isColourExpanded = false;
  bool _isBrandExpanded = false;

  late final double _priceUpperBound;

  @override
  void initState() {
    super.initState();
    _priceUpperBound = widget.maxPrice > 0 ? widget.maxPrice : 1500;
    _selectedPopularFilters =
        widget.initialPopularFilters != null &&
            widget.initialPopularFilters!.isNotEmpty
        ? Set<String>.from(widget.initialPopularFilters!)
      : <String>{};
    selectedBrands = Set<String>.from(widget.initialSelectedBrands ?? <String>{});
    selectedColor = widget.initialSelectedColor ?? '';
    final initialRange = widget.initialPriceRange ?? RangeValues(0, _priceUpperBound);
    currentPriceRange = RangeValues(
      initialRange.start.clamp(0, _priceUpperBound),
      initialRange.end.clamp(0, _priceUpperBound),
    );

    _minPriceController = TextEditingController(
      text: currentPriceRange.start.toInt().toString(),
    );
    _maxPriceController = TextEditingController(
      text: currentPriceRange.end.toInt().toString(),
    );
    _minPriceFocusNode = FocusNode();
    _maxPriceFocusNode = FocusNode();

    _minPriceFocusNode.addListener(() {
      if (!_minPriceFocusNode.hasFocus) {
        _commitMinPriceInput();
      }
    });
    _maxPriceFocusNode.addListener(() {
      if (!_maxPriceFocusNode.hasFocus) {
        _commitMaxPriceInput();
      }
    });
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minPriceFocusNode.dispose();
    _maxPriceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.75;

    return SizedBox(
      height: sheetHeight,
      child: Container(
        decoration: const BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      _sheetTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _darkTextColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _resetAllFilters,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Reset all',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1.5,
                            letterSpacing: -0.32,
                            color: _accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 0.5, thickness: 0.5, color: _borderColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Popular Filters',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: _darkTextColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _popularFilters
                          .map((String filter) =>
                              _buildPopularFilterChip(context, filter))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 0.5, thickness: 0.5, color: _borderColor),
                    _buildFilterTile(
                      title: 'Price Range',
                      iconAssetPath: 'assets/price.png',
                      isExpanded: _isPriceRangeExpanded,
                      actionLabel: (currentPriceRange.start > 0 ||
                              currentPriceRange.end < _priceUpperBound)
                          ? 'Clear'
                          : null,
                      onActionTap: (currentPriceRange.start > 0 ||
                              currentPriceRange.end < _priceUpperBound)
                          ? () {
                              setState(() {
                                currentPriceRange = RangeValues(0, _priceUpperBound);
                                _syncPriceControllers();
                              });
                            }
                          : null,
                      onExpansionChanged: (bool value) {
                        setState(() {
                          _isPriceRangeExpanded = value;
                        });
                      },
                      children: <Widget>[
                        _buildPriceRangeContent(),
                      ],
                    ),
                    const Divider(height: 0.5, thickness: 0.5, color: _borderColor),
                    _buildFilterTile(
                      title: 'Colour',
                      iconAssetPath: 'assets/color.png',
                      isExpanded: _isColourExpanded,
                      actionLabel: selectedColor.isNotEmpty ? 'Clear' : null,
                      onActionTap: selectedColor.isNotEmpty
                          ? () {
                              setState(() {
                                selectedColor = '';
                              });
                            }
                          : null,
                      onExpansionChanged: (bool value) {
                        setState(() {
                          _isColourExpanded = value;
                        });
                      },
                      children: <Widget>[
                        _buildColourContent(),
                      ],
                    ),
                    const Divider(height: 0.5, thickness: 0.5, color: _borderColor),
                    _buildFilterTile(
                      title: 'Brand',
                      iconAssetPath: 'assets/verified.png',
                      isExpanded: _isBrandExpanded,
                      actionLabel: 'View all',
                      onActionTap: () {
                        setState(() {
                          _isBrandExpanded = true;
                        });
                      },
                      onExpansionChanged: (bool value) {
                        setState(() {
                          _isBrandExpanded = value;
                        });
                      },
                      children: <Widget>[
                        _buildBrandContent(),
                      ],
                    ),
                    const Divider(height: 0.5, thickness: 0.5, color: _borderColor),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: _backgroundColor,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply?.call(Set<String>.from(_selectedPopularFilters));
                    widget.onApplySelection?.call(
                      FilterBottomSheetSelection(
                        popularFilters: Set<String>.from(_selectedPopularFilters),
                        selectedBrands: Set<String>.from(selectedBrands),
                        selectedColor: selectedColor,
                        currentPriceRange: currentPriceRange,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontFamily: 'Inter',
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

  Widget _buildPopularFilterChip(BuildContext context, String label) {
    final bool isActive = _selectedPopularFilters.contains(label);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _selectedPopularFilters.remove(label);
          } else {
            _selectedPopularFilters.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? _accentColor.withValues(alpha: 0.10)
              : _primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(29),
          border: isActive ? Border.all(color: _accentColor, width: 1) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _darkTextColor,
          ),
        ),
      ),
    );
  }

  int get _appliedFilterCount {
    int count = 0;

    count += _selectedPopularFilters.length;
    count += selectedBrands.length;

    if (selectedColor.isNotEmpty) {
      count += 1;
    }

    if (currentPriceRange.start > 0 || currentPriceRange.end < _priceUpperBound) {
      count += 1;
    }

    return count;
  }

  String get _sheetTitle {
    final int count = _appliedFilterCount;
    if (count <= 0) {
      return 'Filters';
    }
    return 'Filters ($count)';
  }

  void _resetAllFilters() {
    setState(() {
      _selectedPopularFilters.clear();
      selectedBrands.clear();
      selectedColor = '';
      currentPriceRange = RangeValues(0, _priceUpperBound);
      _isPriceRangeExpanded = false;
      _isColourExpanded = false;
      _isBrandExpanded = false;
      _syncPriceControllers();
    });
  }

  Widget _buildFilterTile({
    required String title,
    required String iconAssetPath,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required List<Widget> children,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey<String>('expansion-$title-$isExpanded'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 0),
        childrenPadding: const EdgeInsets.only(left: 36, right: 8, bottom: 12),
        leading: Image.asset(
          iconAssetPath,
          width: 20,
          height: 20,
          fit: BoxFit.contain,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _darkTextColor,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (actionLabel != null && onActionTap != null)
              GestureDetector(
                onTap: onActionTap,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.5,
                      letterSpacing: -0.32,
                      color: _accentColor,
                    ),
                  ),
                ),
              ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: _primaryColor,
            ),
          ],
        ),
        iconColor: _primaryColor,
        collapsedIconColor: _primaryColor,
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        children: children,
      ),
    );
  }

  Widget _buildBrandContent() {
    final List<Widget> rows = <Widget>[];
    final List<MapEntry<String, int>> entries = _brandOptions.entries.toList();

    for (int index = 0; index < entries.length; index++) {
      final MapEntry<String, int> entry = entries[index];
      final String brandName = entry.key;
      final int productCount = entry.value;
      final bool isSelected = selectedBrands.contains(brandName);

      rows.add(
        InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedBrands.remove(brandName);
              } else {
                selectedBrands.add(brandName);
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _primaryColor, width: 1),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        brandName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$productCount products',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (index != entries.length - 1) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return Column(children: rows);
  }

  Widget _buildColourContent() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: _colourOptions.entries.map((MapEntry<String, Color> entry) {
        final String colourName = entry.key;
        final Color colourValue = entry.value;
        final bool isSelected = selectedColor == colourName;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColor = colourName;
            });
          },
          child: SizedBox(
            width: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colourValue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _primaryColor : _borderColor,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  colourName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected ? _primaryColor : _mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primaryColor,
            inactiveTrackColor: const Color(0xFFE8E8E8),
            thumbColor: _primaryColor,
            overlayColor: _primaryColor.withValues(alpha: 0.12),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: RangeSlider(
            values: currentPriceRange,
            min: 0,
            max: _priceUpperBound,
            onChanged: (RangeValues values) {
              setState(() {
                currentPriceRange = RangeValues(
                  values.start.roundToDouble(),
                  values.end.roundToDouble(),
                );
                _syncPriceControllers();
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildPriceBox(
                controller: _minPriceController,
                focusNode: _minPriceFocusNode,
                onChanged: _onMinPriceChanged,
                onSubmitted: (_) => _commitMinPriceInput(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '-',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  color: _mutedTextColor,
                ),
              ),
            ),
            Expanded(
              child: _buildPriceBox(
                controller: _maxPriceController,
                focusNode: _maxPriceFocusNode,
                onChanged: _onMaxPriceChanged,
                onSubmitted: (_) => _commitMaxPriceInput(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        border: Border.all(color: const Color(0xFFCAE9FF), width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9DB2CE),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          prefixText: '\$',
          prefixStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF9DB2CE),
          ),
        ),
      ),
    );
  }

  void _onMinPriceChanged(String value) {
    if (value.isEmpty) {
      return;
    }
    final int? parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      return;
    }

    final int minValue = _clampPrice(parsedValue);
    final int currentMax = currentPriceRange.end.toInt();
    final int adjustedMax = currentMax < minValue ? minValue : currentMax;

    setState(() {
      currentPriceRange = RangeValues(minValue.toDouble(), adjustedMax.toDouble());
      _syncPriceControllers();
    });
  }

  void _onMaxPriceChanged(String value) {
    if (value.isEmpty) {
      return;
    }
    final int? parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      return;
    }

    final int maxValue = _clampPrice(parsedValue);
    final int currentMin = currentPriceRange.start.toInt();
    final int adjustedMin = currentMin > maxValue ? maxValue : currentMin;

    setState(() {
      currentPriceRange = RangeValues(adjustedMin.toDouble(), maxValue.toDouble());
      _syncPriceControllers();
    });
  }

  void _commitMinPriceInput() {
    if (_minPriceController.text.trim().isEmpty) {
      _syncPriceControllers();
      return;
    }
    _onMinPriceChanged(_minPriceController.text);
    _syncPriceControllers();
  }

  void _commitMaxPriceInput() {
    if (_maxPriceController.text.trim().isEmpty) {
      _syncPriceControllers();
      return;
    }
    _onMaxPriceChanged(_maxPriceController.text);
    _syncPriceControllers();
  }

  int _clampPrice(int value) {
    return value.clamp(0, _priceUpperBound).toInt();
  }

  void _syncPriceControllers() {
    final String minText = currentPriceRange.start.toInt().toString();
    final String maxText = currentPriceRange.end.toInt().toString();

    if (!_minPriceFocusNode.hasFocus && _minPriceController.text != minText) {
      _minPriceController.text = minText;
    }
    if (!_maxPriceFocusNode.hasFocus && _maxPriceController.text != maxText) {
      _maxPriceController.text = maxText;
    }
  }
}
