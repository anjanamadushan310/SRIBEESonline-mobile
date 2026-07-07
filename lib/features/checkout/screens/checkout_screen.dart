/// SRIBEESonline - Finalize Order (Checkout)
///
/// Pushed from Cart. Delivery address → payment method (SRIBEES Wallet toggle +
/// select gateway) → order summary (from the real cart) → terms → Place Order
/// (gated by the terms checkbox). Placing the order calls POST /orders (the
/// backend builds the order from the server-side Redis cart and clears it),
/// then navigates to the Order Confirmation screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/design/sribees_design.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../cart/models/cart_model.dart';
import '../../onboarding/screens/address_form_screen.dart';
import '../providers/payment_method_provider.dart';
import 'order_confirmation_screen.dart';

/// Server-authoritative order totals from POST /orders/quote. No figure here is
/// computed on the client — the app renders exactly what the server returns.
class _OrderQuote {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tax;
  final double walletDeduction;
  final double cashbackEarned;
  final double total;
  final double walletBalance;
  final bool walletApplied;
  final int itemCount;

  const _OrderQuote({
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.tax,
    required this.walletDeduction,
    required this.cashbackEarned,
    required this.total,
    required this.walletBalance,
    required this.walletApplied,
    required this.itemCount,
  });

  factory _OrderQuote.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return _OrderQuote(
      subtotal: d('subtotal'),
      deliveryFee: d('delivery_fee'),
      discount: d('discount'),
      tax: d('tax'),
      walletDeduction: d('wallet_deduction'),
      cashbackEarned: d('cashback_earned'),
      total: d('total'),
      walletBalance: d('wallet_balance'),
      walletApplied: json['wallet_applied'] as bool? ?? false,
      itemCount: json['item_count'] as int? ?? 0,
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _walletOn = true;
  bool _agree = false;
  bool _placing = false;

  /// Selected payment method code (e.g. 'COD' / 'WALLET'), from the
  /// payment-methods API. Defaults to the first method once loaded.
  String? _selectedMethodCode;

  /// Delivery address loaded from GET /user/addresses (default or first).
  Map<String, dynamic>? _address;
  bool _loadingAddress = false;

  /// Server-authoritative totals from POST /orders/quote.
  _OrderQuote? _quote;
  bool _loadingQuote = false;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDeliveryAddress();
      await _fetchQuote();
    });
  }

  Future<void> _loadDeliveryAddress() async {
    if (!ref.read(isAuthenticatedProvider)) return;
    setState(() => _loadingAddress = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>('/user/addresses');
      final data = response['data'];
      final List<dynamic> raw =
          data is List ? data : (data is Map ? (data['addresses'] ?? []) : []);
      final addresses =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (!mounted) return;
      setState(() {
        _address = addresses.isEmpty
            ? null
            : addresses.firstWhere(
                (a) => a['is_default'] == true,
                orElse: () => addresses.first,
              );
        _loadingAddress = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  /// Fetch the exact server-calculated totals. Called on load and whenever an
  /// input that affects pricing changes (wallet toggle, address, cart/coupon).
  Future<void> _fetchQuote() async {
    if (!ref.read(isAuthenticatedProvider)) return;
    setState(() {
      _loadingQuote = true;
      _quoteError = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final addressId =
          (_address?['address_id'] ?? _address?['id'] ?? '').toString();
      final response = await api.post<Map<String, dynamic>>(
        '/orders/quote',
        data: {
          if (addressId.isNotEmpty) 'delivery_address_id': addressId,
          'use_wallet': _walletOn,
        },
      );
      final data = Map<String, dynamic>.from(
        (response['data'] as Map?) ?? <String, dynamic>{},
      );
      if (!mounted) return;
      setState(() {
        _quote = _OrderQuote.fromJson(data);
        _loadingQuote = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingQuote = false;
        _quoteError = 'Could not load totals. Pull to retry.';
      });
    }
  }

  void _toggleWallet() {
    setState(() => _walletOn = !_walletOn);
    _fetchQuote();
  }

  String get _addressLabel {
    final a = _address;
    if (a == null) return 'Add a delivery address';
    final parts = [
      a['address_line1'] ?? a['address_line_1'] ?? '',
      a['address_line2'] ?? a['address_line_2'] ?? '',
      a['post_office'] ?? '',
      a['district'] ?? '',
    ].where((s) => s.toString().isNotEmpty);
    return parts.join(', ');
  }

  Future<void> _changeAddress() async {
    final a = _address;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
          addressId: a == null
              ? null
              : (a['address_id'] ?? a['id'] ?? '').toString(),
          initialProvince: a?['province'],
          initialDistrict: a?['district'],
          initialPostOffice: a?['post_office'],
          initialAddressLine1: a?['address_line1'] ?? a?['address_line_1'],
          initialAddressLine2: a?['address_line2'] ?? a?['address_line_2'],
        ),
      ),
    );
    if (mounted) {
      await _loadDeliveryAddress();
      await _fetchQuote();
    }
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    if (!_agree) {
      showToast(context, 'Please agree to the terms');
      return;
    }
    if (!ref.read(isAuthenticatedProvider)) {
      showToast(context, 'Please log in to place your order');
      return;
    }
    final addressId =
        (_address?['address_id'] ?? _address?['id'] ?? '').toString();
    if (addressId.isEmpty) {
      showToast(context, 'Please add a delivery address first');
      return;
    }

    setState(() => _placing = true);
    try {
      final api = ref.read(apiClientProvider);
      // The backend creates the order from the server-side cart and clears it.
      final response = await api.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'delivery_address_id': addressId,
          'payment_method': _selectedMethodCode ?? 'COD',
          'use_wallet': _walletOn,
        },
      );

      final order = Map<String, dynamic>.from(
        (response['data'] as Map?) ?? <String, dynamic>{},
      );

      // Sync the local cart state with the (now empty) server cart, and refresh
      // every view that the new order touches so the Orders/Notifications tabs
      // and wallet reflect it immediately (no manual pull-to-refresh needed).
      await ref.read(cartProvider.notifier).loadCart();
      ref.invalidate(walletProvider);
      ref.invalidate(walletTransactionsProvider);
      ref.invalidate(ordersListProvider);
      ref.invalidate(notificationsProvider); // unread count derives from this

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      showToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _placing = false);
      showToast(context, 'Could not place the order. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    // Wallet balance fallback for the label before the first quote arrives.
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;
    final methodsAsync = ref.watch(paymentMethodsProvider);

    // Re-quote when the cart contents or applied coupon change.
    ref.listen(cartProvider, (prev, next) {
      if (prev == null) return;
      if (prev.itemCount != next.itemCount ||
          prev.coupon?.code != next.coupon?.code) {
        _fetchQuote();
      }
    });

    // Default the selection to the first method once they load.
    ref.listen(paymentMethodsProvider, (prev, next) {
      next.whenData((methods) {
        if (_selectedMethodCode == null && methods.isNotEmpty) {
          setState(() => _selectedMethodCode = methods.first.code);
        }
      });
    });

    final items = cart.items;
    final quote = _quote;
    final walletBalance = quote?.walletBalance ?? wallet.balance;
    final walletDeduction = quote?.walletDeduction ?? 0.0;
    final total = quote?.total ?? 0.0;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backButton(),
              const SizedBox(height: 16),
              const Text('Finalize Order',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                      letterSpacing: -0.3)),
              const SizedBox(height: 6),
              const Text(
                  'Review your details before we prepare your delivery.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF5A5A64), height: 1.4)),
              const SizedBox(height: 24),

              _deliveryCard(),
              const SizedBox(height: 16),
              _paymentCard(walletBalance, walletDeduction, total, methodsAsync),
              const SizedBox(height: 16),
              _summaryCard(items, quote),
              const SizedBox(height: 16),

              // Terms
              GestureDetector(
                onTap: () => setState(() => _agree = !_agree),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: kFill, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CheckBox(selected: _agree),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 13, height: 1.5, color: kInk2),
                            children: [
                              TextSpan(text: "I agree to the SRIBEES' "),
                              TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                      color: kMagentaAppbarStart,
                                      fontWeight: FontWeight.w700)),
                              TextSpan(text: ' and '),
                              TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                      color: kMagentaAppbarStart,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Place order
              GestureDetector(
                onTap: _placeOrder,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: (_agree && !_placing)
                        ? swatch(kMagenta, kMagentaDeep)
                        : null,
                    color: (_agree && !_placing)
                        ? null
                        : const Color(0xFFF1C7D8),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: _placing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Place Order',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(width: 9),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          SribeesBottomNav(selected: 2, onTap: (i) => popToTab(context, ref, i)),
      floatingActionButton: SribeesSparkleFab(
          onTap: () => showToast(context, '✨ AI shopping assistant')),
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

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cardShadow(opacity: 0.18),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: kMagenta, size: 18),
        const SizedBox(width: 9),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
      ],
    );
  }

  Widget _deliveryCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.location_on_rounded, 'Delivery Address'),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _changeAddress,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                  color: kFill, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined,
                      color: Color(0xFF8C8C97), size: 17),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                        _loadingAddress ? 'Loading address...' : _addressLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kInk)),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: kMuted, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Contact Phone Number',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A5A64))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder, width: 1.5),
            ),
            child: Row(
              children: const [
                Icon(Icons.phone_outlined, color: kMuted, size: 16),
                SizedBox(width: 10),
                Text('07X XXX XXXX',
                    style: TextStyle(
                        fontSize: 13,
                        color: kPlaceholder,
                        letterSpacing: 0.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(
    double walletBalance,
    double walletDeduction,
    double total,
    AsyncValue<List<PaymentMethod>> methodsAsync,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.credit_card_rounded, 'Payment Method'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFFCE7F0),
                borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        color: kMagenta, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SRIBEES Wallet',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kInk)),
                          const SizedBox(height: 1),
                          Text('Balance: Rs. ${money(walletBalance)}',
                              style: const TextStyle(
                                  fontSize: 11, color: kMuted)),
                        ],
                      ),
                    ),
                    _Toggle(
                      on: _walletOn,
                      onTap: _toggleWallet,
                    ),
                  ],
                ),
                if (_walletOn) ...[
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Amount applied',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kInk2)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(12)),
                    child: _loadingQuote
                        ? const Text('Calculating…',
                            style: TextStyle(fontSize: 14, color: kMuted))
                        : Text('Rs.  ${money(walletDeduction)}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                  ),
                  if (!_loadingQuote && walletDeduction > 0) ...[
                    const SizedBox(height: 9),
                    Text(
                      'Rs. ${money(walletDeduction)} will be deducted from your '
                      'total. Please pay the remaining Rs. ${money(total)} using '
                      'another method.',
                      style: TextStyle(
                          fontSize: 11,
                          color: kMagentaAppbarStart.withValues(alpha: 0.85),
                          height: 1.5),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Pay with',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A5A64))),
          const SizedBox(height: 8),
          // Payment options rendered dynamically from GET /payment-methods.
          methodsAsync.when(
            data: (methods) {
              if (methods.isEmpty) {
                return const Text('No payment methods available.',
                    style: TextStyle(fontSize: 13, color: kMuted));
              }
              final selectedCode = _selectedMethodCode ?? methods.first.code;
              return Column(
                children: [
                  for (var i = 0; i < methods.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _methodTile(methods[i], methods[i].code == selectedCode),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: kMagenta),
                  ),
                  SizedBox(width: 10),
                  Text('Loading payment methods…',
                      style: TextStyle(fontSize: 13, color: kMuted)),
                ],
              ),
            ),
            error: (_, __) => const Text(
                'Could not load payment methods. Please try again.',
                style: TextStyle(fontSize: 13, color: kMuted)),
          ),
        ],
      ),
    );
  }

  /// A selectable payment-method row (radio-style).
  Widget _methodTile(PaymentMethod method, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMethodCode = method.code),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCE7F0) : kFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kMagenta : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(method.icon,
                color: selected ? kMagenta : const Color(0xFF8C8C97), size: 18),
            const SizedBox(width: 11),
            Expanded(
              child: Text(method.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? kMagenta : kInk)),
            ),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(List<CartItem> items, _OrderQuote? quote) {
    // Item lines are just labels; every money figure below is server-authored.
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader(Icons.receipt_long_outlined, 'Order Summary'),
              if (_loadingQuote)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: kMagenta),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Text('No items in your order',
                style: TextStyle(fontSize: 13, color: kMuted))
          else
            ...items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${i.name} (x${i.quantity})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: kInk2)),
                      ),
                      Text('Rs. ${money(i.total)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                    ],
                  ),
                )),
          const _DashedLine(),
          const SizedBox(height: 14),
          if (quote == null)
            _quoteUnavailable()
          else ...[
            _row('Subtotal', 'Rs. ${money(quote.subtotal)}'),
            if (quote.discount > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kSuccess)),
                  Text('- Rs. ${money(quote.discount)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kSuccess)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _row('Delivery Fee', 'Rs. ${money(quote.deliveryFee)}'),
            if (quote.tax > 0) ...[
              const SizedBox(height: 10),
              _row('Tax', 'Rs. ${money(quote.tax)}'),
            ],
            if (quote.walletDeduction > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Wallet Deduction',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kMagentaAppbarStart)),
                  Text('- Rs. ${money(quote.walletDeduction)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kMagentaAppbarStart)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1, color: kBorder),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL AMOUNT',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: kMuted.withValues(alpha: 0.8))),
                    const SizedBox(height: 3),
                    Text('Rs. ${money(quote.total)}',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: kMagenta,
                            letterSpacing: -0.5)),
                  ],
                ),
                Icon(Icons.verified_outlined,
                    size: 26, color: kMagenta.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: kSuccessBg, borderRadius: BorderRadius.circular(12)),
              child: Text(
                'You will earn Rs. ${money(quote.cashbackEarned)} Cash Back on '
                'this order',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: kSuccess,
                    height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A64))),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
      ],
    );
  }

  /// Placeholder shown before the first quote arrives, or when it failed.
  Widget _quoteUnavailable() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (_loadingQuote)
            const SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: kMagenta),
            )
          else
            const Icon(Icons.info_outline_rounded, size: 18, color: kMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadingQuote
                  ? 'Calculating your total…'
                  : (_quoteError ?? 'Totals unavailable.'),
              style: const TextStyle(fontSize: 13, color: kMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bits
// ---------------------------------------------------------------------------

class _Toggle extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const _Toggle({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: on ? kMagentaAppbarStart : const Color(0xFFCFCDD6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: selected ? kMagenta : const Color(0xFFCFCDD6), width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration:
                    const BoxDecoration(color: kMagenta, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool selected;
  const _CheckBox({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? kMagenta : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
            color: selected ? kMagenta : const Color(0xFFCFCDD6), width: 2),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: LayoutBuilder(
        builder: (context, c) {
          const dashW = 5.0, gap = 4.0;
          final count = (c.maxWidth / (dashW + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                  width: dashW, height: 1.5, color: const Color(0xFFD4D1D9)),
            ),
          );
        },
      ),
    );
  }
}
