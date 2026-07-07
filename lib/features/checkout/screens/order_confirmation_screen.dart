/// SRIBEESonline - Order Confirmation
///
/// Success screen shown after POST /orders succeeds. Displays the order
/// number, totals and cashback, with a CTA back to Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  /// `data` object returned by POST /orders (format_order).
  final Map<String, dynamic> order;

  const OrderConfirmationScreen({super.key, required this.order});

  void _continueShopping(BuildContext context, WidgetRef ref) {
    ref.read(mainTabProvider.notifier).state = 0;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderNumber =
        (order['order_number'] ?? order['order_id'] ?? '').toString();
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0;
    final delivery = (order['shipping_amount'] as num?)?.toDouble() ?? 0;
    final itemCount = order['item_count'] as int? ?? 0;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: kSuccessBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kSuccess.withValues(alpha: 0.25),
                      blurRadius: 26,
                      spreadRadius: -6,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: kSuccess, size: 52),
              ),
              const SizedBox(height: 24),
              const Text('Order Placed!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                      letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Text(
                'Thank you for shopping with SRIBEES.\nWe are preparing your delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5,
                    color: kMuted.withValues(alpha: 0.95),
                    height: 1.5),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow(opacity: 0.18),
                ),
                child: Column(
                  children: [
                    _row('Order Number', orderNumber.isEmpty ? '—' : orderNumber,
                        bold: true),
                    const SizedBox(height: 12),
                    _row('Items', '$itemCount'),
                    const SizedBox(height: 12),
                    _row('Subtotal', 'Rs. ${money(subtotal)}'),
                    const SizedBox(height: 12),
                    _row('Delivery Fee', 'Rs. ${money(delivery)}'),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: kBorder),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                        Text('Rs. ${money(total)}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: kMagenta,
                                letterSpacing: -0.4)),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _continueShopping(context, ref),
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: swatch(kMagenta, kMagentaDeep),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Text('Continue Shopping',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A64))),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: kInk)),
      ],
    );
  }
}
