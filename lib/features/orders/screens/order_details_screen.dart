/// SRIBEESonline - Order Details
///
/// Fetches GET /api/v1/orders/{id} and renders:
///   • a vertical status timeline mapping the order's current state,
///   • the ordered items,
///   • the shipping address,
///   • the exact server-provided pricing breakdown (subtotal, delivery,
///     discount, wallet deduction, total, cashback earned).
/// Handles loading and error states.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/design/sribees_design.dart';

/// Fetches a single order by id or order-number. Family key = the id/number.
final orderDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/orders/$orderId');
  final data = response['data'];
  return data is Map
      ? Map<String, dynamic>.from(data)
      : <String, dynamic>{};
});

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          SribeesAppBar(
            title: 'Order Details',
            centerTitle: true,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: orderAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: kMagenta),
              ),
              error: (e, _) => _ErrorState(
                onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
              ),
              data: (order) {
                if (order.isEmpty) {
                  return _ErrorState(
                    message: 'Order not found.',
                    onRetry: () =>
                        ref.invalidate(orderDetailProvider(orderId)),
                  );
                }
                return RefreshIndicator(
                  color: kMagenta,
                  onRefresh: () async {
                    ref.invalidate(orderDetailProvider(orderId));
                    await ref.read(orderDetailProvider(orderId).future);
                  },
                  child: _OrderBody(order: order, providerKey: orderId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Body
// ===========================================================================

class _OrderBody extends StatelessWidget {
  final Map<String, dynamic> order;
  // The orderDetailProvider family key used by the screen (for invalidation
  // after a return is submitted). May be an id or an order number.
  final String providerKey;
  const _OrderBody({required this.order, required this.providerKey});

  double _d(String k) => (order[k] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final number = (order['order_number'] ?? order['order_id'] ?? '').toString();
    final status = (order['status'] ?? 'pending').toString();
    final items = (order['items'] as List?) ?? const [];
    final timeline = (order['status_timeline'] as List?) ?? const [];
    final address = order['delivery_address'] as Map?;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerCard(number, status, items.length),
          const SizedBox(height: 16),
          if (timeline.isNotEmpty) ...[
            _sectionTitle('Order Status'),
            const SizedBox(height: 12),
            _card(child: _Timeline(steps: timeline)),
            const SizedBox(height: 16),
          ],
          _sectionTitle('Items'),
          const SizedBox(height: 12),
          _card(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 22, color: kBorder),
                  _ItemRow(
                    item: Map<String, dynamic>.from(items[i] as Map),
                  ),
                ],
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No items on this order',
                        style: TextStyle(fontSize: 13, color: kMuted)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (address != null) ...[
            _sectionTitle('Delivery Address'),
            const SizedBox(height: 12),
            _card(child: _AddressBlock(address: Map<String, dynamic>.from(address))),
            const SizedBox(height: 16),
          ],
          _sectionTitle('Payment Summary'),
          const SizedBox(height: 12),
          _card(child: _pricing()),

          // Return Items — only offered while the order is DELIVERED.
          if (status.toLowerCase() == 'delivered') ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _openReturnSheet(
                context,
                (order['order_id'] ?? '').toString(),
                providerKey,
              ),
              icon: const Icon(Icons.assignment_return_outlined, size: 20),
              label: const Text('Return Items'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kMagenta,
                side: const BorderSide(color: kMagenta, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],

          // Download Invoice — available once the order is confirmed onward.
          if (const {'confirmed', 'shipped', 'delivered', 'refunded'}
              .contains(status.toLowerCase())) ...[
            SizedBox(height: status.toLowerCase() == 'delivered' ? 12 : 20),
            _InvoiceButton(
              apiOrderId: (order['order_id'] ?? '').toString(),
              orderNumber: number,
            ),
          ],
        ],
      ),
    );
  }

  void _openReturnSheet(
      BuildContext context, String apiOrderId, String providerKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ReturnRequestSheet(apiOrderId: apiOrderId, providerKey: providerKey),
    );
  }

  Widget _headerCard(String number, String status, int itemCount) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ORDER',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: kMagenta)),
                const SizedBox(height: 3),
                Text(number,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kInk)),
                const SizedBox(height: 2),
                Text('$itemCount item${itemCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 13, color: kMuted)),
              ],
            ),
          ),
          _StatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _pricing() {
    final walletDeduction = _d('wallet_deduction');
    final discount = _d('discount_amount');
    final tax = _d('tax_amount');
    final cashback = _d('cashback_earned');
    return Column(
      children: [
        _row('Subtotal', _d('subtotal')),
        if (discount > 0) _row('Discount', -discount, highlight: kSuccess),
        _row('Delivery Fee', _d('shipping_amount')),
        if (tax > 0) _row('Tax', tax),
        if (walletDeduction > 0)
          _row('Wallet Deduction', -walletDeduction,
              highlight: kMagentaAppbarStart),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: kBorder),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
            Text('Rs. ${money(_d('total_amount'))}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kMagenta,
                    letterSpacing: -0.4)),
          ],
        ),
        if (cashback > 0) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: kSuccessBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, color: kSuccess, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You earned Rs. ${money(cashback)} Cash Back on this order',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: kSuccess,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, double value, {Color? highlight}) {
    final sign = value < 0 ? '- ' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      highlight != null ? FontWeight.w600 : FontWeight.w400,
                  color: highlight ?? const Color(0xFF5A5A64))),
          Text('${sign}Rs. ${money(value.abs())}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: highlight ?? kInk)),
        ],
      ),
    );
  }
}

// ===========================================================================
// Status timeline
// ===========================================================================

class _Timeline extends StatelessWidget {
  final List steps;
  const _Timeline({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            step: Map<String, dynamic>.from(steps[i] as Map),
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final Map<String, dynamic> step;
  final bool isLast;
  const _TimelineStep({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final completed = step['completed'] == true;
    final current = step['current'] == true;
    final label = (step['label'] ?? '').toString();
    final cancelled = step['status'] == 'cancelled' || step['status'] == 'refunded';
    final ts = step['timestamp'];
    final dotColor = cancelled
        ? const Color(0xFFCF3A3A)
        : (completed ? kMagenta : const Color(0xFFD4D1D9));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: completed ? dotColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 2),
                ),
                child: completed
                    ? Icon(cancelled ? Icons.close_rounded : Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: completed ? kMagenta : const Color(0xFFE2DFE6),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                      color: completed ? kInk : kMuted,
                    ),
                  ),
                  if (ts != null) ...[
                    const SizedBox(height: 2),
                    Text(_formatTimestamp(ts.toString()),
                        style: const TextStyle(fontSize: 12, color: kMuted)),
                  ] else if (current) ...[
                    const SizedBox(height: 2),
                    const Text('In progress',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kMagenta)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Item row / address / status badge / helpers
// ===========================================================================

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = (item['product_name'] ?? '').toString();
    final qty = item['quantity'] as int? ?? 1;
    final lineTotal = (item['subtotal'] as num?)?.toDouble() ??
        ((item['unit_price'] as num?)?.toDouble() ?? 0) * qty;
    final image = item['product_image']?.toString();

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: kFill,
            borderRadius: BorderRadius.circular(11),
            image: (image != null && image.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(image), fit: BoxFit.cover)
                : null,
          ),
          child: (image == null || image.isEmpty)
              ? const Icon(Icons.image_outlined, color: kMuted, size: 20)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 2),
              Text('Qty: $qty',
                  style: const TextStyle(fontSize: 12, color: kMuted)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text('Rs. ${money(lineTotal)}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: kInk)),
      ],
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final Map<String, dynamic> address;
  const _AddressBlock({required this.address});

  @override
  Widget build(BuildContext context) {
    final lines = [
      address['address_line1'],
      address['address_line2'],
      address['post_office'],
      address['district'],
      address['province'],
      address['postal_code'],
    ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined, color: kMagenta, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            lines.isEmpty ? 'No address on file' : lines,
            style: const TextStyle(fontSize: 13, height: 1.5, color: kInk2),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    late final Color bg;
    late final Color fg;
    if (s == 'delivered') {
      bg = kSuccessBg;
      fg = kSuccess;
    } else if (s == 'cancelled' || s == 'refunded') {
      bg = const Color(0xFFFAD9D9);
      fg = const Color(0xFFCF3A3A);
    } else {
      bg = kMagentaTint;
      fg = kMagenta;
    }
    final label = status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({this.message = 'Could not load this order.', required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFC2BECE)),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: kMuted)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
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
}

// ===========================================================================
// Download invoice button
// ===========================================================================

class _InvoiceButton extends ConsumerStatefulWidget {
  final String apiOrderId;
  final String orderNumber;
  const _InvoiceButton({required this.apiOrderId, required this.orderNumber});

  @override
  ConsumerState<_InvoiceButton> createState() => _InvoiceButtonState();
}

class _InvoiceButtonState extends ConsumerState<_InvoiceButton> {
  bool _busy = false;

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final bytes = await api.getBytes('/orders/${widget.apiOrderId}/invoice');

      final dir = await getTemporaryDirectory();
      final safe = widget.orderNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File('${dir.path}/invoice_$safe.pdf');
      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice saved, but could not open it: ${result.message}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not download the invoice. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _download,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: kMagenta),
            )
          : const Icon(Icons.receipt_long_outlined, size: 20),
      label: Text(_busy ? 'Preparing…' : 'Download Invoice'),
      style: OutlinedButton.styleFrom(
        foregroundColor: kMagenta,
        side: const BorderSide(color: kMagenta, width: 1.5),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ===========================================================================
// Return request bottom sheet
// ===========================================================================

class _ReturnRequestSheet extends ConsumerStatefulWidget {
  final String apiOrderId;
  final String providerKey;
  const _ReturnRequestSheet({
    required this.apiOrderId,
    required this.providerKey,
  });

  @override
  ConsumerState<_ReturnRequestSheet> createState() =>
      _ReturnRequestSheetState();
}

class _ReturnRequestSheetState extends ConsumerState<_ReturnRequestSheet> {
  static const _reasons = [
    'Damaged or defective item',
    'Wrong item received',
    'Item not as described',
    'Quality not satisfactory',
    'Other',
  ];

  String? _reason;
  final _commentsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        '/orders/${widget.apiOrderId}/return',
        data: {
          'reason': _reason,
          if (_commentsCtrl.text.trim().isNotEmpty)
            'comments': _commentsCtrl.text.trim(),
        },
      );
      // Refresh the order so the new RETURN_REQUESTED state shows immediately.
      ref.invalidate(orderDetailProvider(widget.providerKey));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request submitted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit return. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2DFE6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Return Items',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: 4),
          const Text('Tell us why you want to return this order.',
              style: TextStyle(fontSize: 13, color: kMuted)),
          const SizedBox(height: 18),
          const Text('Reason',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.map((r) {
              final selected = _reason == r;
              return GestureDetector(
                onTap: _submitting ? null : () => setState(() => _reason = r),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? kMagentaTint : kFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? kMagenta : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Text(r,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? kMagenta : kInk2)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text('Additional comments (optional)',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentsCtrl,
            maxLines: 3,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: 'Add any details…',
              filled: true,
              fillColor: kFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_reason == null || _submitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: kMagenta,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Submit Return Request',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// Shared bits ---------------------------------------------------------------

Widget _sectionTitle(String title) => Text(
      title,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800, color: kInk),
    );

Widget _card({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow(opacity: 0.16),
      ),
      child: child,
    );

String _formatTimestamp(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final local = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour < 12 ? 'AM' : 'PM';
  final mm = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, ${local.year} · $h:$mm $ampm';
}
