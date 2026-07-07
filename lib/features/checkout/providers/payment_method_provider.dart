/// SRIBEESonline - Payment Methods Provider
///
/// Fetches the checkout payment options from GET /api/v1/payment-methods so the
/// Checkout screen renders them dynamically instead of hardcoding cards.
///
/// MVP methods: Cash on Delivery (COD) and the internal SRIBEES Wallet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';

class PaymentMethod {
  final String id;
  final String code; // 'COD' | 'WALLET' — sent to POST /orders
  final String name;
  final String type; // 'OFFLINE' | 'WALLET'
  final bool isActive;

  const PaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString().toUpperCase(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString().toUpperCase(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// A representative icon per method type for the checkout UI.
  IconData get icon {
    switch (code) {
      case 'WALLET':
        return Icons.account_balance_wallet_outlined;
      case 'COD':
        return Icons.local_shipping_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}

/// Available payment methods for checkout. Rebuilt on auth changes; returns an
/// empty list for guests (checkout is auth-gated anyway).
final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  if (!ref.watch(isAuthenticatedProvider)) return const [];
  final api = ref.watch(apiClientProvider);

  final response = await api.get<Map<String, dynamic>>('/payment-methods');
  final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? response;
  final raw = (data['methods'] as List?) ?? const [];

  return raw
      .map((e) => PaymentMethod.fromJson(Map<String, dynamic>.from(e as Map)))
      .where((m) => m.isActive)
      .toList();
});
