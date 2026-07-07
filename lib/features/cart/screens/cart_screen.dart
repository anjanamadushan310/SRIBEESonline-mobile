/// SRIBEESonline - Cart screen
///
/// Pushed full screen, matching the "SRIBEES Online" prototype: back button →
/// "Your Cart" → Select-All / Remove Selected → cart lines (checkbox, gradient
/// thumb, price, qty stepper) → profit banner → subtotal / delivery / grand
/// total → Checkout. Driven by the real [cartProvider]; selection, profit and
/// totals recompute from the selected lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';
import '../../../core/providers/cart_provider.dart';
import '../../checkout/screens/checkout_screen.dart';
import '../models/cart_model.dart';

// Delivery/total figures are server-authoritative (from GET /cart). Only this
// display-only "profit" estimate remains a client-side marketing calc.
const double _profitRate = 0.135;

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // Keys explicitly deselected (empty ⇒ everything selected, incl. new items).
  final Set<String> _deselected = {};

  bool _isSelected(CartItem item) => !_deselected.contains(item.itemKey);

  void _toggle(CartItem item) {
    setState(() {
      final k = item.itemKey;
      if (_deselected.contains(k)) {
        _deselected.remove(k);
      } else {
        _deselected.add(k);
      }
    });
  }

  void _toggleSelectAll(List<CartItem> items, bool allOn) {
    setState(() {
      _deselected.clear();
      if (allOn) {
        _deselected.addAll(items.map((i) => i.itemKey));
      }
    });
  }

  void _removeSelected(List<CartItem> items) {
    final selected = items.where(_isSelected).toList();
    if (selected.isEmpty) {
      showToast(context, 'Select items to remove');
      return;
    }
    final notifier = ref.read(cartProvider.notifier);
    for (final item in selected) {
      notifier.removeItem(
          productId: item.productId, variantId: item.variantId);
    }
    showToast(context, 'Removed selected items');
  }

  void _goToTab(int index) {
    ref.read(mainTabProvider.notifier).state = index;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final items = cart.items;

    final selected = items.where(_isSelected).toList();
    final selCount = selected.length;
    final allOn = items.isNotEmpty && _deselected.isEmpty;
    // Server-authoritative totals for the whole cart (GET /cart) — the same
    // figures the checkout quote and final order use. Selection remains a
    // client-only concept for the "Remove Selected" bulk action.
    final subtotal = cart.subtotal;
    final discount = cart.totals?.discount ?? 0;
    final delivery = cart.totals?.shipping ?? 0;
    final grand = cart.total;
    final profit = (subtotal * _profitRate).round().toDouble();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: items.isEmpty
            ? _emptyState()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _backButton(),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Cart',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$selCount Items selected',
                      style: const TextStyle(fontSize: 15, color: kMuted),
                    ),
                    const SizedBox(height: 20),

                    // Select all row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: kBorder,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleSelectAll(items, allOn),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                _Check(selected: allOn),
                                const SizedBox(width: 12),
                                const Text(
                                  'Select All Items',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: kInk),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeSelected(items),
                            child: const Text(
                              'Remove Selected',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kMagenta),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lines
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CartLine(
                            item: item,
                            selected: _isSelected(item),
                            onToggle: () => _toggle(item),
                            onInc: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  productId: item.productId,
                                  variantId: item.variantId,
                                  quantity: item.quantity + 1,
                                ),
                            onDec: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  productId: item.productId,
                                  variantId: item.variantId,
                                  quantity: item.quantity - 1,
                                ),
                          ),
                        )),

                    // Add more
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Forgot something? ',
                                style: TextStyle(
                                    fontSize: 15, color: Color(0xFF5A5A64))),
                            GestureDetector(
                              onTap: () => _goToTab(0),
                              child: const Text('Add more items',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: kMagenta)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2DFE6)),
                    const SizedBox(height: 18),

                    // Profit banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: kSuccessBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_outlined,
                              color: kSuccess, size: 22),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'Your Profit This Order: Rs. ${money(profit)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kSuccess),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Totals (server-authoritative)
                    _totalRow('Subtotal (${items.length} items)',
                        'Rs. ${money(subtotal)}'),
                    if (discount > 0) ...[
                      const SizedBox(height: 9),
                      _totalRow('Discount', '- Rs. ${money(discount)}'),
                    ],
                    const SizedBox(height: 9),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child:
                          _totalRow('Delivery Fee', 'Rs. ${money(delivery)}'),
                    ),
                    const _DashedDivider(),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GRAND TOTAL',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: kMuted)),
                            const SizedBox(height: 2),
                            Text('Rs. ${money(grand)}',
                                style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: kMagenta,
                                    letterSpacing: -1)),
                          ],
                        ),
                        Icon(Icons.shopping_cart_outlined,
                            size: 34,
                            color: kMagenta.withValues(alpha: 0.25)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Checkout
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CheckoutScreen()),
                      ),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kMagenta,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: kMagenta.withValues(alpha: 0.5),
                              blurRadius: 28,
                              spreadRadius: -12,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Checkout',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SribeesBottomNav(selected: -1, onTap: _goToTab),
      floatingActionButton: SribeesSparkleFab(
        onTap: () => showToast(context, '✨ AI shopping assistant'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: kMagenta,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kMagenta.withValues(alpha: 0.5),
              blurRadius: 14,
              spreadRadius: -6,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 15, color: Color(0xFF5A5A64))),
        Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
      ],
    );
  }

  Widget _emptyState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Align(alignment: Alignment.centerLeft, child: _backButton()),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 56, color: kPlaceholder),
                SizedBox(height: 12),
                Text('Your cart is empty',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cart line
// ---------------------------------------------------------------------------

class _CartLine extends StatelessWidget {
  final CartItem item;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _CartLine({
    required this.item,
    required this.selected,
    required this.onToggle,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cardShadow(opacity: 0.18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: _Check(selected: selected),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: gradientFor(item.productId),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                      height: 1.15),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Rs. ${money(item.price)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: kMagenta),
                      ),
                    ),
                    _QtyStepper(
                        qty: item.quantity, onInc: onInc, onDec: onDec),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _QtyStepper(
      {required this.qty, required this.onInc, required this.onDec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kFill,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDec,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.remove, size: 16, color: kInk2),
            ),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: kInk),
            ),
          ),
          GestureDetector(
            onTap: onInc,
            child: Container(
              width: 30,
              height: 30,
              decoration:
                  const BoxDecoration(color: kMagenta, shape: BoxShape.circle),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checkbox + dashed divider
// ---------------------------------------------------------------------------

class _Check extends StatelessWidget {
  final bool selected;
  const _Check({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? kMagenta : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? kMagenta : const Color(0xFFCFCDD6),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashW = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashW + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1.5,
              color: const Color(0xFFD4D1D9),
            ),
          ),
        );
      },
    );
  }
}
