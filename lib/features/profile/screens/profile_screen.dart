/// SRIBEESonline - Profile tab
///
/// Account / rewards / settings. Refined "Silicon Valley premium" scale:
/// compact avatar + identity, restrained badges, a slimmer rewards card, and
/// lighter list rows with generous whitespace between groups.
/// Rendered inside the main shell's IndexedStack (no own Scaffold/header).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';
import '../../../core/providers/notification_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../payment/screens/payment_methods_screen.dart';
import '../../rewards/screens/cashback_history_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          // Avatar + identity
          _avatar(context),
          const SizedBox(height: 16),
          const Text('Kasun Perera',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                  letterSpacing: -0.3)),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'SR12345'));
              showToast(context, 'ID copied to clipboard');
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('ID: SR12345',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6A6A74))),
                SizedBox(width: 6),
                Icon(Icons.copy_rounded, size: 13, color: Color(0xFF9B97A1)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: kMagenta, borderRadius: BorderRadius.circular(999)),
                child: const Text('GOLD MEMBER',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6)),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.stars_rounded, color: kMagenta, size: 16),
                  SizedBox(width: 5),
                  Text('2,450 Points',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kInk)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Rewards card
          _rewardsCard(context),
          const SizedBox(height: 30),

          // Menu
          _MenuRow(
            icon: Icons.person_outline_rounded,
            label: 'My Account',
            sub: 'Personal info, addresses',
            onTap: () => showToast(context, 'My Account'),
          ),
          const SizedBox(height: 12),
          _MenuRow(
            icon: Icons.credit_card_rounded,
            label: 'Payment Methods',
            sub: 'Visa, Mastercard, Koko',
            onTap: () => _push(context, const PaymentMethodsScreen()),
          ),
          const SizedBox(height: 12),
          _MenuRow(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            sub: 'Offers, order updates',
            showDot: unreadCount > 0,
            onTap: () => _push(context, const NotificationsScreen()),
          ),
          const SizedBox(height: 12),
          _MenuRow(
            icon: Icons.settings_outlined,
            label: 'Settings',
            sub: 'Security, privacy, language',
            onTap: () => showToast(context, 'Settings'),
          ),
          const SizedBox(height: 12),
          _MenuRow(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            sub: 'FAQ, contact us',
            onTap: () => showToast(context, 'Help & Support'),
          ),
          const SizedBox(height: 12),
          _MenuRow(
            icon: Icons.group_outlined,
            label: 'Invite Friends',
            sub: 'Get Rs. 200 for each friend',
            onTap: () => showToast(context, 'Invite Friends'),
          ),
          const SizedBox(height: 24),

          // Logout
          GestureDetector(
            onTap: () => showToast(context, 'Logged out'),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EE),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.logout_rounded,
                        color: kMagenta, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Logout',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kMagenta)),
                        SizedBox(height: 2),
                        Text('SIGN OUT OF YOUR ACCOUNT',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Color(0xFFCF7D9C))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFE3A9C1), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('SRIBEES V4.2.0 · SRILANKA',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: Color(0xFFC2BECE))),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: kMagenta, width: 2.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    swatch(const Color(0xFFC98B6A), const Color(0xFF9A5D44)),
              ),
              alignment: Alignment.center,
              child: const Text('KP',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: GestureDetector(
              onTap: () => showToast(context, 'Edit profile'),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kMagentaDeep,
                  shape: BoxShape.circle,
                  border: Border.all(color: kBg, width: 2.5),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _push(context, const CashBackHistoryScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: swatch(kMagenta, kMagentaDeep),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kMagenta.withValues(alpha: 0.30),
              blurRadius: 40,
              spreadRadius: -22,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SRIBEES REWARDS',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2)),
                  SizedBox(height: 6),
                  Text('Rs. 450.00',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5)),
                  SizedBox(height: 3),
                  Text('Cash Back Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool showDot;
  final VoidCallback onTap;
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow(opacity: 0.12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: kMagentaTint,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: kMagenta, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      if (showDot) ...[
                        const SizedBox(width: 7),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: kMagenta, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFC2BECE), size: 18),
          ],
        ),
      ),
    );
  }
}
