/// SRIBEESonline - Wallet & Cashback Providers
///
/// Fetches the real wallet balance and transaction history from the backend:
///
///   GET /wallet               -> balance, currency, cashback_rate
///   GET /wallet/transactions  -> paginated earned/spent history
///
/// The wallet is per-user, so both providers are rebuilt on login/logout and
/// short-circuit to an empty/zero state for guests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_provider.dart';

// =============================================================================
// Models
// =============================================================================

class Wallet {
  final double balance;
  final String currency;
  final double cashbackRate;

  const Wallet({
    this.balance = 0,
    this.currency = 'LKR',
    this.cashbackRate = 0.10,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'LKR',
      cashbackRate: (json['cashback_rate'] ?? json['cashbackRate'] as num?)
              ?.toDouble() ??
          0.10,
    );
  }

  static const empty = Wallet(balance: 0, currency: 'LKR', cashbackRate: 0.10);
}

class WalletTransaction {
  final String id;
  final String type; // 'earned' | 'spent' | 'refund'
  final String title;
  final double amount;
  final String? orderNumber;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.orderNumber,
    this.createdAt,
  });

  bool get isEarned => type == 'earned' || type == 'refund';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['transaction_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'earned').toString(),
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      orderNumber: json['order_number'] as String? ?? json['orderNumber'] as String?,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

// =============================================================================
// Providers
// =============================================================================

/// Current wallet balance / cashback rate. Rebuilt when auth changes.
final walletProvider = FutureProvider<Wallet>((ref) async {
  if (!ref.watch(isAuthenticatedProvider)) return Wallet.empty;
  final api = ref.watch(apiClientProvider);
  final response = await api.get<dynamic>('/wallet');
  // GET /wallet returns the balance object directly (not wrapped in `data`).
  final map = response is Map
      ? Map<String, dynamic>.from(response)
      : <String, dynamic>{};
  final data = map['data'];
  return Wallet.fromJson(
    data is Map ? Map<String, dynamic>.from(data) : map,
  );
});

/// Paginated wallet transactions (first page). Rebuilt when auth changes.
final walletTransactionsProvider =
    FutureProvider<List<WalletTransaction>>((ref) async {
  if (!ref.watch(isAuthenticatedProvider)) return const [];
  final api = ref.watch(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    '/wallet/transactions',
    queryParameters: {'page': 1, 'page_size': 50},
  );
  final data = response['data'];
  final List<dynamic> raw = data is Map
      ? (data['transactions'] as List? ?? [])
      : (data is List ? data : []);
  return raw
      .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
