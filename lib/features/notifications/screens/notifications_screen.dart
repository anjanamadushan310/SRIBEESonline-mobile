/// SRIBEESonline - Notifications
///
/// Pushed screen: magenta app bar → hero banner → real "Recent" feed
/// (GET /notifications) → "For You" grid. Tapping an unread notification marks
/// it read (PATCH /notifications/{id}/read); "Mark all as read" hits
/// PUT /notifications/read-all. Loading, error, empty and pull-to-refresh
/// states are handled. Bottom nav (Profile active) + FAB.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';
import '../../../core/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final actions = ref.read(notificationActionsProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          SribeesAppBar(
            title: 'Notifications',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kMagenta,
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
                await ref.read(notificationsProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroBanner(),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: kInk)),
                        GestureDetector(
                          onTap: () async {
                            await actions.markAllRead();
                            if (context.mounted) {
                              showToast(context, 'All marked as read');
                            }
                          },
                          child: const Text('Mark all as read',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kMagentaAppbarStart)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _feed(context, ref, notificationsAsync, actions),
                    const SizedBox(height: 30),
                    const Text('For You',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ForYouTile(
                            iconBg: kMagentaTint,
                            icon: Icons.settings_outlined,
                            iconColor: kMagenta,
                            label: 'Notifications',
                            onTap: () =>
                                showToast(context, 'Notification settings'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ForYouTile(
                            iconBg: const Color(0xFFE3E2E4),
                            icon: Icons.help_outline_rounded,
                            iconColor: const Color(0xFF6A6A74),
                            label: 'Help Center',
                            onTap: () => showToast(context, 'Help Center'),
                          ),
                        ),
                      ],
                    ),
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

  Widget _feed(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AppNotification>> async,
    NotificationActions actions,
  ) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: kMagenta)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 38, color: Color(0xFFC9C5D0)),
              const SizedBox(height: 12),
              const Text('Could not load notifications',
                  style: TextStyle(fontSize: 14, color: kMuted)),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Retry',
                    style: TextStyle(
                        color: kMagenta, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 44),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 40, color: Color(0xFFC9C5D0)),
                  SizedBox(height: 12),
                  Text('You’re all caught up',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB3AFBA))),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final n in items) ...[
              _NotifCard(
                notification: n,
                onTap: n.isRead ? null : () => actions.markRead(n.id),
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _heroBanner() {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B1419), Color(0xFF5A3A2C), Color(0xFF8A2350)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF14080C).withValues(alpha: 0.55),
                  const Color(0xFF14080C).withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.7],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: kMagenta,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Text('LATEST UPDATES',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ),
                const SizedBox(height: 12),
                const Text('Stay Fresh,\nStay Informed.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.05)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  const _NotifCard({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final visual = notificationVisual(notification.type);
    final unread = !notification.isRead;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unread ? kCard : kFill,
          borderRadius: BorderRadius.circular(16),
          border:
              unread ? Border.all(color: kMagentaTint, width: 1.5) : null,
          boxShadow: unread ? cardShadow(opacity: 0.14) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(color: visual.iconBg, shape: BoxShape.circle),
              child: Icon(visual.icon, color: visual.iconColor, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: kInk)),
                      ),
                      Text(notificationTimeAgo(notification.createdAt),
                          style:
                              const TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message,
                      style: const TextStyle(
                          fontSize: 14, height: 1.45, color: kInk2)),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 9,
                height: 9,
                decoration:
                    const BoxDecoration(color: kMagenta, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ForYouTile extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _ForYouTile({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: kFill,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          ],
        ),
      ),
    );
  }
}
