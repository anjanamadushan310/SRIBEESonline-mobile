/// SRIBEESonline - Main shell + Home tab
///
/// `HomeScreen` is the app's tabbed shell (Home / Saved / Orders / Profile)
/// matching the "SRIBEES Online" prototype: a shared magenta header and white
/// bottom nav with a center sparkle FAB stay fixed while the body switches
/// between tab bodies (IndexedStack keeps each tab's state). Cart and Product
/// open as pushed routes on top of the shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';
import '../../../core/providers/branch_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/product_provider.dart';
import '../../products/models/product_model.dart';
import '../../products/screens/search_screen.dart';
import '../../products/widgets/product_card.dart';
import '../../cart/screens/cart_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../onboarding/screens/address_selection_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../saved/screens/saved_screen.dart';

// ---------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  final String? branchName;
  const HomeScreen({super.key, this.branchName});

  void _openCart(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(mainTabProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          SribeesHeader(
            onMenu: () => showToast(context, 'Menu'),
            onCart: () => _openCart(context),
          ),
          Expanded(
            child: IndexedStack(
              index: tab,
              children: const [
                _HomeTab(),
                SavedTab(),
                OrdersTab(),
                ProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SribeesBottomNav(
        selected: tab,
        onTap: (i) => ref.read(mainTabProvider.notifier).state = i,
      ),
      floatingActionButton: SribeesSparkleFab(
        onTap: () => showToast(context, '✨ AI shopping assistant'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ---------------------------------------------------------------------------
// Deal data (gradient placeholders, mirrors the prototype)
// ---------------------------------------------------------------------------

class _Category {
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color a;
  final Color b;
  const _Category(this.name, this.icon, this.iconColor, this.a, this.b);
}

const _categories = <_Category>[
  _Category('Agro', Icons.eco_outlined, Color(0xFF3F7A2C), Color(0xFFCFE8C0),
      Color(0xFFA6D68F)),
  _Category('Groceries', Icons.shopping_bag_outlined, Color(0xFFA06B1A),
      Color(0xFFF2DCB4), Color(0xFFE3BF80)),
  _Category('Electronics', Icons.devices_other_outlined, Color(0xFF4A5A72),
      Color(0xFFCDD6E2), Color(0xFFA5B2C4)),
  _Category('Express', Icons.delivery_dining_outlined, kMagenta,
      Color(0xFFFBD9E6), Color(0xFFF4B3CD)),
  _Category('Meat', Icons.kebab_dining_outlined, Color(0xFFB0463F),
      Color(0xFFF0C0BD), Color(0xFFDD8E88)),
];

class _Banner {
  final String title;
  final String subtitle;
  final Color a;
  final Color b;
  const _Banner(this.title, this.subtitle, this.a, this.b);
}

const _banners = <_Banner>[
  _Banner('Fresh Farm Produce', 'Delivered straight to you.', Color(0xFF7A4A2C),
      Color(0xFFD68A3C)),
  _Banner('20% Off Greens', 'This weekend only.', Color(0xFF5A7A3C),
      Color(0xFF9BBF5C)),
  _Banner('Earn 10% Cash Back', 'On every single order.', Color(0xFF8A3A4C),
      Color(0xFFC5607A)),
];

// ---------------------------------------------------------------------------
// Home tab body
// ---------------------------------------------------------------------------

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final _pageController = PageController();
  int _bannerPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addProduct(Product p) {
    ref.read(cartProvider.notifier).addItem(
          productId: p.id,
          price: p.effectivePrice,
          name: p.name,
          imageUrl: p.primaryImageUrl,
          sku: p.sku,
        );
    showToast(context, '${p.name} added to cart');
  }

  void _openSearch() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  /// Opens the address selector so the user can switch their delivery location.
  void _changeLocation() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickSale = ref.watch(quickSaleProductsProvider);
    final branch = ref.watch(branchProvider);
    final locationLabel = (branch?.postOffice?.isNotEmpty ?? false)
        ? branch!.postOffice!
        : (branch?.branchName.isNotEmpty ?? false)
            ? branch!.branchName
            : 'Select location';

    return RefreshIndicator(
      color: kMagenta,
      onRefresh: () async {
        ref.invalidate(quickSaleProductsProvider);
        await ref.read(quickSaleProductsProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeliveringToBar(label: locationLabel, onTap: _changeLocation),
            const SizedBox(height: 14),
            _SearchPill(onTap: _openSearch),
            const SizedBox(height: 22),
            _BannerCarousel(
              controller: _pageController,
              page: _bannerPage,
              onPageChanged: (p) => setState(() => _bannerPage = p),
              onDot: (i) => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
              ),
              onShop: () => showToast(context, 'Browse today’s deals below'),
            ),
            const SizedBox(height: 26),
            const _SectionTitle('Shop by Category'),
            const SizedBox(height: 16),
            _CategoryRow(onTap: (c) => showToast(context, '${c.name} category')),
            const SizedBox(height: 30),
            const _SectionTitle('Quick Sale'),
            const SizedBox(height: 16),
            _QuickSaleGrid(
              state: quickSale,
              onOpen: (p) => openProductDetails(context, p),
              onAdd: _addProduct,
              onRetry: () => ref.invalidate(quickSaleProductsProvider),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Sale grid (real data)
// ---------------------------------------------------------------------------

class _QuickSaleGrid extends StatelessWidget {
  final AsyncValue<List<Product>> state;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;
  final VoidCallback onRetry;

  const _QuickSaleGrid({
    required this.state,
    required this.onOpen,
    required this.onAdd,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: kMagenta)),
      ),
      error: (e, _) => _message(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load products',
        action: TextButton(
          onPressed: onRetry,
          child: const Text('Retry', style: TextStyle(color: kMagenta)),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return _message(
            icon: Icons.local_offer_outlined,
            title: 'No Quick Sale items right now',
            subtitle: 'Check back soon for fresh deals.',
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => ProductGridCard(
            product: products[i],
            onOpen: () => onOpen(products[i]),
            onAdd: () => onAdd(products[i]),
          ),
        );
      },
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFC9C5D0)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kInk)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(fontSize: 13, color: kMuted)),
            ],
            if (action != null) ...[
              const SizedBox(height: 8),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search pill
// ---------------------------------------------------------------------------

class _DeliveringToBar extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DeliveringToBar({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: kMagenta, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Delivering to',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kMuted)),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: kInk),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: kInk, size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: kBorder, width: 1.5),
          boxShadow: cardShadow(opacity: 0.10),
        ),
        child: Row(
          children: const [
            Icon(Icons.search_rounded, color: Color(0xFF9B97A1), size: 22),
            SizedBox(width: 11),
            Text('Search for.......',
                style: TextStyle(color: kPlaceholder, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: kInk,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banner carousel
// ---------------------------------------------------------------------------

class _BannerCarousel extends StatelessWidget {
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onDot;
  final VoidCallback onShop;

  const _BannerCarousel({
    required this.controller,
    required this.page,
    required this.onPageChanged,
    required this.onDot,
    required this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: _banners.length,
              itemBuilder: (_, i) =>
                  _BannerSlide(banner: _banners[i], onShop: onShop),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == page;
            return GestureDetector(
              onTap: () => onDot(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                height: 6,
                width: active ? 20 : 6,
                decoration: BoxDecoration(
                  color: active ? kMagenta : const Color(0xFFD7D3DC),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final _Banner banner;
  final VoidCallback onShop;
  const _BannerSlide({required this.banner, required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
            decoration: BoxDecoration(gradient: swatch(banner.a, banner.b))),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF32190A).withValues(alpha: 0.6),
                const Color(0xFF32190A).withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.68],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    shadows: [
                      Shadow(
                          color: Color(0x4D000000),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                banner.subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92), fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onShop,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                  decoration: BoxDecoration(
                      color: kMagenta, borderRadius: BorderRadius.circular(22)),
                  child: const Text(
                    'Shop Now',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category row
// ---------------------------------------------------------------------------

class _CategoryRow extends StatelessWidget {
  final ValueChanged<_Category> onTap;
  const _CategoryRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final c = _categories[i];
          return GestureDetector(
            onTap: () => onTap(c),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 66,
              child: Column(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      gradient: swatch(c.a, c.b),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1.5),
                    ),
                    child: Icon(c.icon, color: c.iconColor, size: 30),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kInk2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

