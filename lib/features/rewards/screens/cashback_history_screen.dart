/// SRIBEESonline - Cash Back History
///
/// Pushed from the Profile rewards card: balance card → filter chips
/// (All / Earned / Spent) → activity list (earned credited / spent debited).
/// Driven by the real wallet APIs (GET /wallet, GET /wallet/transactions).
/// Bottom nav (Profile active) + FAB.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';
import '../../../core/providers/wallet_provider.dart';

enum _CbFilter { all, earned, spent }

const _earnedGreen = Color(0xFF2F8A3C);
const _spentRed = Color(0xFFCF3A3A);

String _formatDate(DateTime? d) {
  if (d == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

class CashBackHistoryScreen extends ConsumerStatefulWidget {
  const CashBackHistoryScreen({super.key});

  @override
  ConsumerState<CashBackHistoryScreen> createState() =>
      _CashBackHistoryScreenState();
}

class _CashBackHistoryScreenState extends ConsumerState<CashBackHistoryScreen> {
  _CbFilter _filter = _CbFilter.all;

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          SribeesAppBar(
            title: 'Cash Back History',
            centerTitle: true,
            onBack: () => Navigator.of(context).maybePop(),
            trailing: GestureDetector(
              onTap: () => showToast(context, 'Cash back help'),
              child: const Icon(Icons.help_outline_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kMagenta,
              onRefresh: () async {
                ref.invalidate(walletProvider);
                ref.invalidate(walletTransactionsProvider);
                await ref.read(walletTransactionsProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _balanceCard(walletAsync.valueOrNull?.balance),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        _chip('All', _CbFilter.all),
                        const SizedBox(width: 10),
                        _chip('Earned', _CbFilter.earned),
                        const SizedBox(width: 10),
                        _chip('Spent', _CbFilter.spent),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const Text('Recent Activities',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    const SizedBox(height: 16),
                    _activityList(txAsync),
                  ],
                ),
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

  Widget _activityList(AsyncValue<List<WalletTransaction>> txAsync) {
    return txAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: kMagenta)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 34, color: Color(0xFFC2BECE)),
              const SizedBox(height: 10),
              const Text('Could not load your cash back history',
                  style: TextStyle(fontSize: 14, color: kPlaceholder)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    ref.invalidate(walletTransactionsProvider),
                child: const Text('Retry',
                    style: TextStyle(color: kMagenta)),
              ),
            ],
          ),
        ),
      ),
      data: (all) {
        final list = all.where((a) {
          switch (_filter) {
            case _CbFilter.all:
              return true;
            case _CbFilter.earned:
              return a.isEarned;
            case _CbFilter.spent:
              return !a.isEarned;
          }
        }).toList();

        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded,
                      size: 34, color: Color(0xFFC2BECE)),
                  SizedBox(height: 10),
                  Text('No cash back activity yet',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kPlaceholder)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            ...list.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ActivityCard(tx: a),
                )),
            const SizedBox(height: 10),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded,
                      size: 34, color: Color(0xFFC2BECE)),
                  SizedBox(height: 10),
                  Text('End of History',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kPlaceholder)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _balanceCard(double? balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: swatch(kMagenta, kMagentaAppbarStart),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kMagenta.withValues(alpha: 0.4),
            blurRadius: 38,
            spreadRadius: -22,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT CASH BACK BALANCE',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(balance == null ? 'Rs. —' : 'Rs. ${money(balance)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5)),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => showToast(context, 'Redeem cash back'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Text('Redeem Now',
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

  Widget _chip(String label, _CbFilter filter) {
    final active = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
        decoration: BoxDecoration(
          color: active ? kMagenta : kBorder,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : const Color(0xFF6A6A74),
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final WalletTransaction tx;
  const _ActivityCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final earned = tx.isEarned;
    final color = earned ? _earnedGreen : _spentRed;
    final orderRef = tx.orderNumber != null && tx.orderNumber!.isNotEmpty
        ? 'Order ${tx.orderNumber}'
        : 'Wallet';
    final date = _formatDate(tx.createdAt);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow(opacity: 0.18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: earned
                  ? const Color(0xFFD8F0CC)
                  : const Color(0xFFFAD9D9),
              shape: BoxShape.circle,
            ),
            child: Icon(earned ? Icons.add : Icons.remove,
                color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kInk)),
                const SizedBox(height: 3),
                Text(date.isEmpty ? orderRef : '$orderRef · $date',
                    style: const TextStyle(fontSize: 13, color: kMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${earned ? '+' : '–'}Rs. ${money(tx.amount)}',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 5),
              Text(earned ? 'CREDITED' : 'DEBITED',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
