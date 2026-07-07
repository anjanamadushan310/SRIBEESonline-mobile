/// SRIBEESonline - Payment Methods
///
/// Pushed screen: saved cards (single-select radios), digital wallets
/// (SRIBEES Wallet + Koko), and Cash on Delivery. Selecting a card clears COD
/// and vice-versa. Bottom nav (Profile active) + FAB.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';

enum _Pay { visa, master, cod }

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  _Pay _selected = _Pay.visa;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          SribeesAppBar(
            title: 'Payment Methods',
            onBack: () => Navigator.of(context).maybePop(),
            trailing: GestureDetector(
              onTap: () => showToast(context, 'Payment help'),
              child: const Icon(Icons.help_outline_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saved Cards',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kInk)),
                      GestureDetector(
                        onTap: () => showToast(context, 'Manage saved cards'),
                        child: const Text('MANAGE',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: kMagentaAppbarStart)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _CardRow(
                    thumb: _visaThumb(),
                    title: 'Visa •••• 4242',
                    sub: 'Expires 12/26',
                    selected: _selected == _Pay.visa,
                    onTap: () => setState(() => _selected = _Pay.visa),
                  ),
                  const SizedBox(height: 22),
                  _CardRow(
                    thumb: _masterThumb(),
                    title: 'Mastercard •••• 8812',
                    sub: 'Expires 09/25',
                    selected: _selected == _Pay.master,
                    onTap: () => setState(() => _selected = _Pay.master),
                  ),
                  const SizedBox(height: 36),

                  const Text('Digital Wallets',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kInk)),
                  const SizedBox(height: 16),
                  _walletCard(context),
                  const SizedBox(height: 24),
                  _kokoRow(context),
                  const SizedBox(height: 36),

                  const Text('Other Methods',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kInk)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _selected = _Pay.cod),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.only(left: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                            left: BorderSide(
                                color: Color(0xFFECC9DA), width: 3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                                color: const Color(0xFFD8F0CC),
                                borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.payments_outlined,
                                color: Color(0xFF2F8A3C), size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cash on Delivery',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: kInk)),
                                SizedBox(height: 2),
                                Text('Pay when you receive',
                                    style: TextStyle(
                                        fontSize: 14, color: kMuted)),
                              ],
                            ),
                          ),
                          _Radio(selected: _selected == _Pay.cod),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          SribeesBottomNav(selected: 3, onTap: (i) => popToTab(context, ref, i)),
      floatingActionButton: SribeesSparkleFab(
          onTap: () => showToast(context, '✨ AI shopping assistant')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _visaThumb() {
    return Container(
      width: 54,
      height: 38,
      decoration: BoxDecoration(
        gradient: swatch(const Color(0xFFCFD6DC), const Color(0xFFAEB6BF)),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 18,
        height: 14,
        decoration: BoxDecoration(
            color: const Color(0xFF1F3A5A),
            borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  Widget _masterThumb() {
    return Container(
      width: 54,
      height: 38,
      decoration: BoxDecoration(
        gradient: swatch(const Color(0xFF3A3A3A), const Color(0xFF1C1C1C)),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
                color: Color(0xFFE0413A), shape: BoxShape.circle),
          ),
          Transform.translate(
            offset: const Offset(-5, 0),
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFFF3A83C), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: swatch(kMagenta, kMagentaAppbarStart),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kMagenta.withValues(alpha: 0.4),
            blurRadius: 36,
            spreadRadius: -20,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SRIBEES WALLET',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    SizedBox(height: 6),
                    Text('Rs. 450.00',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1)),
                  ],
                ),
              ),
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 30),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => showToast(context, 'Opening wallet top-up…'),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Text('Top Up Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kokoRow(BuildContext context) {
    return GestureDetector(
      onTap: () => showToast(context, 'Koko — pay in 3'),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Text('Koko.',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Koko',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kInk)),
                SizedBox(height: 2),
                Text('Pay in 3 installments',
                    style: TextStyle(fontSize: 14, color: kMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFC2BECE), size: 24),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final Widget thumb;
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _CardRow({
    required this.thumb,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          thumb,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kInk)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 14, color: kMuted)),
              ],
            ),
          ),
          _Radio(selected: selected),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? kMagenta : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? kMagenta : const Color(0xFFE3B9CC),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}
