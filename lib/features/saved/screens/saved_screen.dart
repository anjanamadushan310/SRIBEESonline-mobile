/// SRIBEESonline - Saved tab
///
/// Real wishlist from GET /api/v1/wishlist: cart-summary card → "Saved Items"
/// → 2-col grid of saved products (optimistic heart toggle, network image with
/// gradient fallback, "10% Cash Back" badge, price-drop pill, Add button).
/// Loading, error, empty and pull-to-refresh states are handled. Tapping a
/// card opens Product Details with the real product id.
/// Rendered inside the main shell's IndexedStack (no own Scaffold/header).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/wishlist_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../products/screens/product_details_screen.dart';
import '../repositories/wishlist_repository.dart';

class SavedTab extends ConsumerStatefulWidget {
  const SavedTab({super.key});

  @override
  ConsumerState<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<SavedTab> {
  void _openCart() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _unlike(WishlistItem item) async {
    // Optimistic: the card disappears immediately; reverts on failure.
    final outcome = await ref.read(wishlistProvider.notifier).toggle(
          productId: item.productId,
          variantId: item.variantId,
        );
    if (!mounted) return;
    switch (outcome) {
      case WishlistToggleOutcome.removed:
        _snack('Removed from saved');
      case WishlistToggleOutcome.failed:
        _snack('Could not update your wishlist. Please try again.');
      default:
        break;
    }
  }

  void _add(WishlistItem item) {
    ref.read(cartProvider.notifier).addItem(
          productId: item.productId,
          variantId: item.variantId,
          price: item.effectivePrice,
          name: item.name,
          imageUrl: item.imageUrl,
        );
    showToast(context, '${item.name} added to cart');
  }

  void _open(WishlistItem item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        productKey: item.productId,
        productId: item.productId,
        name: item.name,
        unit: item.variantName ?? 'SRIBEES',
        price: item.effectivePrice,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = ref.watch(wishlistProvider);

    return RefreshIndicator(
      color: kMagenta,
      onRefresh: () => ref.read(wishlistProvider.notifier).loadWishlist(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CartSummaryCard(onViewCart: _openCart),
            const SizedBox(height: 24),
            const Text(
              'Saved Items',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kInk,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your curated list of favorite organic produce.',
              style: TextStyle(fontSize: 14, color: kMuted, height: 1.4),
            ),
            const SizedBox(height: 22),
            _body(wishlist),
          ],
        ),
      ),
    );
  }

  Widget _body(WishlistState wishlist) {
    if (wishlist.isLoading && wishlist.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 54),
        child: Center(child: CircularProgressIndicator(color: kMagenta)),
      );
    }
    if (wishlist.error != null && wishlist.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 42, color: Color(0xFFC9C5D0)),
              const SizedBox(height: 12),
              const Text('Could not load your wishlist',
                  style: TextStyle(fontSize: 15, color: kMuted)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(wishlistProvider.notifier).loadWishlist(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMagenta,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (wishlist.items.isEmpty) {
      return _empty();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: wishlist.items.length,
      itemBuilder: (_, i) => _SavedCard(
        item: wishlist.items[i],
        onUnlike: () => _unlike(wishlist.items[i]),
        onAdd: () => _add(wishlist.items[i]),
        onOpen: () => _open(wishlist.items[i]),
      ),
    );
  }

  Widget _empty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 54),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.favorite_border_rounded, size: 44, color: kPlaceholder),
            SizedBox(height: 12),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: kMuted),
            ),
            SizedBox(height: 4),
            Text(
              'Tap the heart on any product to save it here.',
              style: TextStyle(fontSize: 13, color: kPlaceholder),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onUnlike;
  final VoidCallback onAdd;
  final VoidCallback onOpen;
  const _SavedCard({
    required this.item,
    required this.onUnlike,
    required this.onAdd,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _image(),
                    const Align(
                        alignment: Alignment.topLeft, child: CashBackBadge()),
                    if (item.priceDrop > 0)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: kSuccess,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Price drop -${item.priceDropPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onUnlike,
                        child: Container(
                          width: 31,
                          height: 31,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 8,
                                spreadRadius: -3,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              color: kMagenta, size: 17),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kInk,
                height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            item.variantName ?? 'SRIBEES',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: kMuted, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Rs.${money(item.effectivePrice)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: kInk),
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: kMagenta, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Add',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _image() {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: gradientFor(item.productId)),
    );
    final url = item.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
