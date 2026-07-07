/// SRIBEESonline - Notification Providers
///
/// Fetches the user's notifications (GET /notifications), derives the unread
/// badge count, and marks notifications as read (PATCH /notifications/{id}/read
/// and PUT /notifications/read-all). Auth-gated: guests get an empty feed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_provider.dart';

// =============================================================================
// Model
// =============================================================================

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? referenceType;
  final String? referenceId;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.referenceType,
    this.referenceId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['notification_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'system').toString(),
      title: json['title'] as String? ?? '',
      message: (json['message'] ?? json['body'] ?? '').toString(),
      isRead: json['is_read'] as bool? ?? false,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id']?.toString(),
      createdAt: _parseDate(json['created_at']),
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

/// The user's notifications (first page, newest first).
final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  if (!ref.watch(isAuthenticatedProvider)) return const [];
  final api = ref.watch(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    '/notifications',
    queryParameters: {'page': 1, 'limit': 50},
  );
  final data = response['data'];
  final List<dynamic> raw = data is Map
      ? (data['notifications'] as List? ?? [])
      : (data is List ? data : []);
  return raw
      .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

/// Unread count for the bell badge, derived from the loaded feed (0 while
/// loading / for guests).
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

// =============================================================================
// Actions
// =============================================================================

/// Thin controller for notification mutations. Exposed as a provider so widgets
/// can call it without holding a repository reference.
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

class NotificationActions {
  final Ref _ref;
  NotificationActions(this._ref);

  ApiClient get _api => _ref.read(apiClientProvider);

  /// Mark a single notification read (PATCH), then refresh the feed.
  Future<void> markRead(String id) async {
    try {
      await _api.patch<Map<String, dynamic>>('/notifications/$id/read');
    } finally {
      _ref.invalidate(notificationsProvider);
    }
  }

  /// Mark every notification read (PUT /read-all), then refresh the feed.
  Future<void> markAllRead() async {
    try {
      await _api.put<Map<String, dynamic>>('/notifications/read-all');
    } finally {
      _ref.invalidate(notificationsProvider);
    }
  }
}

// =============================================================================
// Presentation helpers
// =============================================================================

/// Icon + colors for a notification card, keyed by its backend `type`.
({IconData icon, Color iconColor, Color iconBg}) notificationVisual(
  String type,
) {
  switch (type) {
    case 'order_status':
    case 'delivery':
      return (
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFF2F8A3C),
        iconBg: const Color(0xFFD8F0CC),
      );
    case 'payment':
      return (
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFFD81B60),
        iconBg: const Color(0xFFFBE3EC),
      );
    case 'price_drop':
    case 'promotion':
      return (
        icon: Icons.local_offer_outlined,
        iconColor: const Color(0xFFD81B60),
        iconBg: const Color(0xFFFBE3EC),
      );
    default:
      return (
        icon: Icons.notifications_none_rounded,
        iconColor: const Color(0xFF6A6A74),
        iconBg: const Color(0xFFE3E2E4),
      );
  }
}

/// Compact relative time (e.g. "2 mins ago", "1 hour ago", "3 days ago").
String notificationTimeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m min${m == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hour${h == 1 ? '' : 's'} ago';
  }
  final days = diff.inDays;
  if (days < 7) return '$days day${days == 1 ? '' : 's'} ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final local = d.toLocal();
  return '${months[local.month - 1]} ${local.day}';
}
