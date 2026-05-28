/// SRIBEESonline - Home Screen
///
/// Main layout with custom AppBar (logo + search), body content,
/// and themed BottomAppBar with notched center FAB (AI Cart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/branch_provider.dart';
import '../../../core/providers/language_provider.dart';

// Brand maroon (task: #8E2157)
const _maroon = Color(0xFF8E2157);

// Localized copy for home (en, si, ta) — matches design: "Favourite", "My Orders"
const _homeCopy = {
  'en': (
    searchHint: 'Search for........',
    home: 'Home',
    favourite: 'Favourite',
    myOrders: 'My Orders',
    profile: 'Profile',
    aiCart: 'AI Cart',
    welcome: 'Welcome to SRIBEESonline!',
    branch: 'Branch',
    quickSale: 'Quick Sale feed will appear here.',
  ),
  'si': (
    searchHint: 'සොයන්න........',
    home: 'මුල් පිටුව',
    favourite: 'ප්‍රියතම',
    myOrders: 'මගේ ඇණවුම්',
    profile: 'පැතිකඩ',
    aiCart: 'AI බඩු රථය',
    welcome: 'SRIBEESonline වෙත පිළිගන්නවා!',
    branch: 'ශාඛාව',
    quickSale: 'ඉක්මන් විකිණීම් මෙහි පෙනෙනු ඇත.',
  ),
  'ta': (
    searchHint: 'தேடு........',
    home: 'முகப்பு',
    favourite: 'பிடித்தவை',
    myOrders: 'எனது ஆர்டர்கள்',
    profile: 'சுயவிவரம்',
    aiCart: 'AI வண்டி',
    welcome: 'SRIBEESonline வரவேற்கிறோம்!',
    branch: 'கிளை',
    quickSale: 'விரைவு விற்பனை இங்கு காணப்படும்.',
  ),
};

class HomeScreen extends ConsumerStatefulWidget {
  /// Optional branch name when navigated from address selection (can also read from [branchProvider]).
  final String? branchName;

  const HomeScreen({super.key, this.branchName});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _t(String? code, String key) {
    final c = _homeCopy[code ?? 'en'] ?? _homeCopy['en']!;
    switch (key) {
      case 'searchHint': return c.searchHint;
      case 'home': return c.home;
      case 'favourite': return c.favourite;
      case 'myOrders': return c.myOrders;
      case 'profile': return c.profile;
      case 'aiCart': return c.aiCart;
      case 'welcome': return c.welcome;
      case 'branch': return c.branch;
      case 'quickSale': return c.quickSale;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final langCode = locale?.languageCode ?? 'en';
    final branch = ref.watch(branchProvider);
    final branchName = widget.branchName ?? branch?.branchName;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(128),
        child: Container(
          color: _maroon,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 8,
            right: 8,
            bottom: 12,
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: hamburger, logo, cart with badge
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SRIBEES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 26),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: const Text(
                              '1',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search bar — capsule, magnifying glass on the right
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: _t(langCode, 'searchHint'),
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                    suffixIcon: Icon(Icons.search_rounded, color: Colors.grey[700], size: 22),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(context, langCode, branchName),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        color: _maroon,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined, _t(langCode, 'home'), 0),
            _navItem(Icons.favorite_border_rounded, _t(langCode, 'favourite'), 1),
            const SizedBox(width: 56), // space for center FAB
            _navItem(Icons.assignment_outlined, _t(langCode, 'myOrders'), 2),
            _navItem(Icons.person_outline_rounded, _t(langCode, 'profile'), 3),
          ],
        ),
      ),
      floatingActionButton: _buildAICartFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// AI Cart FAB: maroon outer ring, white inner circle, cart + "AI" + star inside.
  Widget _buildAICartFab() {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _maroon, width: 3),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_rounded, size: 20, color: _maroon),
                  const SizedBox(width: 2),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: _maroon,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(Icons.star_rounded, size: 12, color: _maroon),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedNavIndex = index),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String langCode, String? branchName) {
    // Main content area: light grey background (design)
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_rounded,
                size: 80,
                color: _maroon.withOpacity(0.3),
              ),
            const SizedBox(height: 24),
            Text(
              _t(langCode, 'welcome'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (branchName != null && branchName.isNotEmpty)
              Text(
                '${_t(langCode, 'branch')}: $branchName',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _maroon,
                    ),
              ),
            const SizedBox(height: 32),
              Text(
                _t(langCode, 'quickSale'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
