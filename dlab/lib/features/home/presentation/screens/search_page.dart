import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _recentSearchesKey = 'recentSearches';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  List<String> _filteredProducts = [];
  List<String> _recentSearches = [];
  bool _isListening = false;

  final List<String> _allProducts = [
    'AirPods',
    'AirPods Pro',
    'AirPods Max',
    'Apple Watch',
    'Apple TV',
    'Amplifier',
    'Action Camera',
    'AV Receiver',
    'Adapter',
    'Alarm Clock (Smart)',
    'Android TV Box',
    'Bluetooth Earphones',
    'Bluetooth Speakers',
    'Batteries',
    'Blu-ray Player',
    'Boombox',
    'Barcode Scanner',
    'Baby Monitor',
    'Body Camera',
    'Broadband Router',
    'Camera',
    'Charging Cable',
    'Computer Monitor',
    'Controller',
    'CPU',
    'Charger',
    'Calculator',
    'Car Stereo',
    'Chromecast',
    'Capture Card',
    'Cooling Pad',
    'Cordless Phone',
    'CRT Monitor',
    'Card Reader',
    'Drone',
    'Desktop PC',
    'Dash Cam',
    'DSLR Camera',
    'DisplayPort Cable',
    'Digital Photo Frame',
    'Docking Station',
    'Drawing Tablet',
    'DAC',
    'Digital Camera',
    'Earphones',
    'Earbuds',
    'Earbuds Wireless',
    'Ear cleaning tool',
    'External Hard Drive',
    'e-Reader',
    'Ethernet Cable',
    'Electric Scooter',
    'Electric Toothbrush',
    'Extension Cord',
    'Fitness Tracker',
    'Flash Drive',
    'Fan (USB)',
    'Film Camera',
    'FM Transmitter',
    'Floppy Drive',
    'Fire TV Stick',
    'Gaming Console',
    'Gaming Mouse',
    'GPU',
    'Gimbal',
    'Gaming Headset',
    'Graphics Tablet',
    'Gamepad',
    'GPS Tracker',
    'Gooseneck Microphone',
    'Gaming Chair',
    'Headphones',
    'Home Theater',
    'HDMI Cable',
    'Hard Drive',
    'Hub (USB)',
    'Hoverboard',
    'Heart Rate Monitor',
    'Headphone Stand',
    'Home Security Camera',
    'HDD',
    'iPad',
    'iPhone',
    'iMac',
    'In-ear monitors',
    'Instant Camera',
    'Inkjet Printer',
    'IP Camera',
    'Intercom System',
    'IEMs',
    'Joystick',
    'Jump Starter (Portable)',
    'Keyboard',
    'Kindle',
    'KVM Switch',
    'Karaoke Machine',
    'Keycap Set',
    'Laptop',
    'LED TV',
    'Lens',
    'Lightning Cable',
    'Laser Printer',
    'Lapel Mic',
    'Light Ring',
    'Lavalier Microphone',
    'Laminator',
    'Laptop Stand',
    'Mouse',
    'MicroSD Card',
    'Microphone',
    'Monitor',
    'Motherboard',
    'Memory Card',
    'MacBook',
    'Mechanical Keyboard',
    'Mac mini',
    'Mac Studio',
    'Modem',
    'MIDI Controller',
    'Megaphone',
    'Mousepad',
    'Noise Cancelling Headphones',
    'Nintendo Switch',
    'NAS',
    'Network Switch',
    'Night Vision Goggles',
    'NVMe SSD',
    'OLED TV',
    'Oculus Quest',
    'Over-ear headphones',
    'Optical Drive',
    'Oscilloscope',
    'Outdoor Camera',
    'On-ear headphones',
    'Power Bank',
    'PlayStation',
    'Projector',
    'PC Case',
    'Printer',
    'Pen Drive',
    'Portable Monitor',
    'Power Supply Unit (PSU)',
    'Phone Case (Battery)',
    'PA System',
    'Point-and-Shoot Camera',
    'Pop Filter',
    'Power Strip',
    'QLED TV',
    'Qi Charger',
    'Quadcopter',
    'Router',
    'RAM',
    'Ring Light',
    'Robot Vacuum',
    'Record Player',
    'Roku',
    'Raspberry Pi',
    'Ring Doorbell',
    'Radio',
    'RGB Strip Lights',
    'Smartphone',
    'Smartwatch',
    'Speaker',
    'SSD',
    'Soundbar',
    'Smart TV',
    'Surge Protector',
    'Smart Plug',
    'Smart Bulb',
    'Server',
    'Scanner',
    'Stylus',
    'Security Camera',
    'Smart Lock',
    'Sound Card',
    'Soldering Iron',
    'Smart Display',
    'Tablet',
    'TV',
    'Tripod',
    'Trackpad',
    'Type-C Cable',
    'Thumb Drive',
    'Thermostat (Smart)',
    'TV Box',
    'Turntable',
    'Two-way Radio',
    'Thunderbolt Dock',
    'USB Drive',
    'USB-C Cable',
    'UPS',
    'Ultrabook',
    'USB Hub',
    'USB Microphone',
    'USB Switch',
    'VR Headset',
    'Video Camera',
    'VGA Cable',
    'Vacuum Cleaner (Robot)',
    'Voice Recorder',
    'Video Doorbell',
    'VHS Player',
    'Vlogging Camera',
    'Wireless Mouse',
    'Wireless Keyboard',
    'Webcam',
    'WiFi Router',
    'Wired Earphones',
    'Walkie Talkie',
    'Weather Station',
    'Wireless Charger',
    'Waterproof Speaker',
    'Xbox Series X',
    'Xbox Series S',
    'Xbox Controller',
    'XQD Card',
    'Yagi Antenna',
    'Zoom Lens',
    'Zip Drive',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
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

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _recentSearches.removeWhere(
        (element) => element.toLowerCase() == trimmed.toLowerCase(),
      );
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.take(5).toList();
      }
    });

    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _recentSearches.remove(query);
    });
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _clearAllRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _recentSearches.clear();
    });
    await prefs.remove(_recentSearchesKey);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = [];
      } else {
        _filteredProducts =
            _allProducts.where((product) {
              final lower = product.toLowerCase();
              final words = lower.split(' ');
              return lower.startsWith(query) ||
                  words.any((word) => word.startsWith(query));
            }).toList();
      }
    });
  }

  void _handleSearchSubmit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _saveRecentSearch(trimmed);
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(query: trimmed),
      ),
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
                Expanded(child: _buildRecommendationsBox())
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
      child: _filteredProducts.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No products found',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          : ListView.separated(
              itemCount: _filteredProducts.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFCAE9FF),
              ),
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    product,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  onTap: () {
                    _searchController.text = product;
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchController.text.length),
                    );
                    _handleSearchSubmit(product);
                  },
                );
              },
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
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFCAE9FF),
              ),
              itemBuilder: (context, index) {
                final query = _recentSearches[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    query,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeRecentSearch(query),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF1B4965),
                    ),
                  ),
                  onTap: () {
                    _searchController.text = query;
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchController.text.length),
                    );
                    _handleSearchSubmit(query);
                  },
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
