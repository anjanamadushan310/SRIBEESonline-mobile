/// SRIBEESonline - Order Providers
///
/// Fetches the user's real order history from GET /api/v1/orders. Auth-gated:
/// guests get an empty list. Rebuilt on login/logout.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_provider.dart';

// =============================================================================
// Model
// =============================================================================

/// Order summary as returned by GET /orders (format_order_summary).
class OrderSummary {
  final String orderId;
  final String orderNumber;
  final String status;
  final double total;
  final double cashbackEarned;
  final int itemCount;
  final DateTime? createdAt;

  const OrderSummary({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.cashbackEarned,
    required this.itemCount,
    this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      orderId: (json['order_id'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? json['order_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      total: (json['total_amount'] as num?)?.toDouble() ?? 0,
      cashbackEarned: (json['cashback_earned'] as num?)?.toDouble() ?? 0,
      itemCount: json['item_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Bucket used by the Orders tab segmented filter.
  bool get isActive => const {
        'pending',
        'confirmed',
        'processing',
        'shipped',
        'out_for_delivery',
      }.contains(status);

  bool get isPast => status == 'delivered' || status == 'cancelled';

  bool get isReturn => status == 'refunded';
}

// =============================================================================
// Providers
// =============================================================================

/// The user's order history (first page, newest first).
final ordersListProvider = FutureProvider<List<OrderSummary>>((ref) async {
  if (!ref.watch(isAuthenticatedProvider)) return const [];
  final api = ref.watch(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    '/orders',
    queryParameters: {'page': 1, 'limit': 50},
  );
  final data = response['data'];
  final List<dynamic> raw = data is Map
      ? (data['orders'] as List? ?? [])
      : (data is List ? data : []);
  return raw
      .map((e) => OrderSummary.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
