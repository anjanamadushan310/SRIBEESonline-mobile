/// SRIBEESonline - Product card + shared product navigation
///
/// A real-data product tile used by the Home "Quick Sale" grid and Search
/// results. Tapping it opens the Product Details screen with the **real**
/// backend product id, which activates the reviews module. The heart button
/// toggles the wishlist optimistically (instant flip, revert on API failure).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';
import '../../../core/providers/wishlist_provider.dart';
import '../../saved/repositories/wishlist_repository.dart';
import '../models/product_model.dart';
import '../screens/product_details_screen.dart';

/// Optimistically toggle a product's wishlist status and surface the outcome
/// as a subtle snackbar. Shared by the grid card and the details screen.
Future<void> toggleWishlist(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
  String? variantId,
  double? priceAtWatch,
}) async {
  final outcome = await ref.read(wishlistProvider.notifier).toggle(
        productId: productId,
        variantId: variantId,
        priceAtWatch: priceAtWatch,
      );
  if (!context.mounted) return;
  final message = switch (outcome) {
    WishlistToggleOutcome.added => 'Saved to your wishlist',
    WishlistToggleOutcome.removed => 'Removed from your wishlist',
    WishlistToggleOutcome.authRequired => 'Please log in to save items',
    WishlistToggleOutcome.failed =>
      'Could not update your wishlist. Please try again.',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1600),
    ));
}

/// Open Product Details for a real backend product (passes the UUID through).
void openProductDetails(BuildContext context, Product product) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        productKey: product.id,
        productId: product.id,
        name: product.name,
        unit: product.categoryName ?? product.brand ?? 'SRIBEES',
        price: product.effectivePrice,
        rating: (product.averageRating ?? 0) > 0
            ? product.averageRating!.toStringAsFixed(1)
            : '—',
      ),
    ),
  );
}

class ProductGridCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSale = product.isOnSale;
    final ratingCount = product.reviewCount ?? 0;
    final isSaved =
        ref.watch(isWishlistedProvider(wishlistKey(product.id, null)));

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _image(),
                    const Align(
                        alignment: Alignment.topLeft, child: CashBackBadge()),
                    if (product.discountPercentage > 0)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: kMagenta,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('-${product.discountPercentage}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    // Heart — optimistic wishlist toggle.
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => toggleWishlist(
                          context,
                          ref,
                          productId: product.id,
                          priceAtWatch: product.effectivePrice,
                        ),
                        child: Container(
                          width: 30,
                          height: 30,
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
                          child: Icon(
                            isSaved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isSaved ? kMagenta : kMuted,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                  height: 1.2),
            ),
            if (ratingCount > 0) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 13, color: Color(0xFFF5B301)),
                  const SizedBox(width: 3),
                  Text(
                    '${(product.averageRating ?? 0).toStringAsFixed(1)} ($ratingCount)',
                    style: const TextStyle(fontSize: 11, color: kMuted),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (onSale)
                        Text(
                          'Rs. ${money(product.price)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: kMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        'Rs. ${money(product.effectivePrice)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kMagenta),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: kMagenta,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kMagenta.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: -4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final url = product.primaryImageUrl;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: gradientFor(product.id)),
    );
    if (url == null || url.isEmpty) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return DecoratedBox(
          decoration: BoxDecoration(gradient: gradientFor(product.id)),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: kMagenta),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
