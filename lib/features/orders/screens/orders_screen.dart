/// SRIBEESonline - Orders tab
///
/// Real order history from GET /api/v1/orders:
///   cart-summary card → "Your Orders" → segmented chips (Active / Past / Return)
///   → order cards (tap "Details" → OrderDetailsScreen with the real order_id).
/// Loading, error, empty and pull-to-refresh states are handled.
/// Rendered inside the main shell's IndexedStack (no own Scaffold/header).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/design/sribees_design.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../cart/screens/cart_screen.dart';
import 'order_details_screen.dart';

enum _OrdersTab { active, past, returns }

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _formatDate(DateTime? d) {
  if (d == null) return '';
  final local = d.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

/// (background, foreground, label) for an order status badge.
(Color, Color, String) _statusStyle(String status) {
  final s = status.toLowerCase();
  if (s == 'delivered') {
    return (kSuccessBg, kSuccess, 'DELIVERED');
  }
  if (s == 'cancelled' || s == 'refunded') {
    return (const Color(0xFFFAD9D9), const Color(0xFFCF3A3A), s.toUpperCase());
  }
  return (kMagentaTint, kMagenta, status.replaceAll('_', ' ').toUpperCase());
}

// ---------------------------------------------------------------------------
// Orders tab
// ---------------------------------------------------------------------------

class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  _OrdersTab _tab = _OrdersTab.active;

  /// order_id currently being re-ordered (drives the button spinner).
  String? _reorderingId;

  void _openCart() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  void _openOrderDetails(String orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderId)),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// POST /orders/{id}/reorder → refresh the cart → open the Cart screen.
  Future<void> _reorder(OrderSummary order) async {
    if (_reorderingId != null) return;
    setState(() => _reorderingId = order.orderId);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/orders/${order.orderId}/reorder',
      );

      // Pull the updated server cart into local state.
      await ref.read(cartProvider.notifier).loadCart();

      final data = response['data'];
      final unavailable = (data is Map ? data['unavailable_items'] : null)
              as List? ??
          const [];

      if (!mounted) return;
      setState(() => _reorderingId = null);
      if (unavailable.isNotEmpty) {
        _snack('${unavailable.length} item(s) were unavailable and skipped.');
      }
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CartScreen()));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _reorderingId = null);
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reorderingId = null);
      _snack('Could not reorder. Please try again.');
    }
  }

  Iterable<OrderSummary> _filter(List<OrderSummary> orders) {
    switch (_tab) {
      case _OrdersTab.active:
        return orders.where((o) => o.isActive);
      case _OrdersTab.past:
        return orders.where((o) => o.isPast);
      case _OrdersTab.returns:
        return orders.where((o) => o.isReturn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider);

    return RefreshIndicator(
      color: kMagenta,
      onRefresh: () async {
        ref.invalidate(ordersListProvider);
        await ref.read(ordersListProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CartSummaryCard(onViewCart: _openCart),
            const SizedBox(height: 24),
            const Text(
              'Your Orders',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kMagenta,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tracking your culinary journey',
              style: TextStyle(fontSize: 14, color: kMuted),
            ),
            const SizedBox(height: 18),

            // Segmented chips
            Row(
              children: [
                _chip('Active Orders', _OrdersTab.active),
                const SizedBox(width: 10),
                _chip('Past Orders', _OrdersTab.past),
                const SizedBox(width: 10),
                _chip('Return Orders', _OrdersTab.returns),
              ],
            ),
            const SizedBox(height: 22),

            ordersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(color: kMagenta)),
              ),
              error: (e, _) => _errorState(),
              data: (orders) {
                final list = _filter(orders).toList();
                if (list.isEmpty) return _emptyState();
                return Column(
                  children: [
                    for (final o in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _OrderCard(
                          order: o,
                          reordering: _reorderingId == o.orderId,
                          onDetails: () => _openOrderDetails(o.orderId),
                          onReorder: () => _reorder(o),
                        ),
                      ),
                    _endOfHistory(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _OrdersTab tab) {
    final active = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kMagenta : kBorder,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF6A6A74),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final (icon, title) = switch (_tab) {
      _OrdersTab.active => (Icons.receipt_long_outlined, 'No active orders'),
      _OrdersTab.past => (Icons.history_rounded, 'No past orders yet'),
      _OrdersTab.returns => (Icons.replay_rounded, 'No return orders'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFC9C5D0)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB3AFBA))),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: Color(0xFFC9C5D0)),
            const SizedBox(height: 12),
            const Text('Could not load your orders',
                style: TextStyle(fontSize: 15, color: kMuted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(ordersListProvider),
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

  Widget _endOfHistory() {
    return const Padding(
      padding: EdgeInsets.only(top: 6, bottom: 6),
      child: Center(
        child: Icon(Icons.history_rounded, size: 34, color: Color(0xFFC2BECE)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order card (real data)
// ---------------------------------------------------------------------------

class _OrderCard extends StatelessWidget {
  final OrderSummary order;
  final bool reordering;
  final VoidCallback onDetails;
  final VoidCallback onReorder;
  const _OrderCard({
    required this.order,
    required this.reordering,
    required this.onDetails,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg, badgeLabel) = _statusStyle(order.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.orderNumber} · ${order.itemCount} '
                      'item${order.itemCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kInk),
                    ),
                    const SizedBox(height: 3),
                    Text(_formatDate(order.createdAt),
                        style: const TextStyle(fontSize: 13, color: kMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(14)),
                child: Text(badgeLabel,
                    style: TextStyle(
                        color: badgeFg,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: kMuted)),
                  const SizedBox(height: 2),
                  Text('Rs. ${money(order.total)}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kMagenta)),
                ],
              ),
              if (order.cashbackEarned > 0)
                Text('Earned: Rs. ${money(order.cashbackEarned)}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kMagenta)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDetails,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                        color: kCard, borderRadius: BorderRadius.circular(22)),
                    child: const Text('Details',
                        style: TextStyle(
                            color: kInk2,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: reordering ? null : onReorder,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: swatch(kMagenta, kMagentaDeep),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: reordering
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Reorder',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
