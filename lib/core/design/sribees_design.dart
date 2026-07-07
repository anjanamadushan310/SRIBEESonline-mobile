/// SRIBEESonline - Shared design system
///
/// Single source of truth for the "SRIBEES Online" handoff design language:
/// colour tokens, gradient/number helpers, and the shared chrome widgets
/// (magenta header, white bottom nav, sparkle FAB, cart-summary card).
///
/// Imagery uses gradient placeholders exactly as the prototype does — swap for
/// product photography when assets land. Fonts: the project bundles no custom
/// fonts, so weights/letter-spacing approximate the intended Poppins/Inter
/// hierarchy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';

// ---------------------------------------------------------------------------
// Colour tokens
// ---------------------------------------------------------------------------
const kMagenta = Color(0xFFD81B60);
const kMagentaLight = Color(0xFFE0457E);
const kMagentaDeep = Color(0xFFB01550);
const kMagentaTint = Color(0xFFFBE3EC);
const kBg = Color(0xFFF6F4F7);
const kCard = Color(0xFFFFFFFF);
const kInk = Color(0xFF1A1A22);
const kInk2 = Color(0xFF3A3A44);
const kMuted = Color(0xFF8C8C97);
const kPlaceholder = Color(0xFFA7A3AD);
const kBorder = Color(0xFFECEAF0);
const kFill = Color(0xFFF0EEF2);
const kSuccess = Color(0xFF1F7A32);
const kSuccessBg = Color(0xFFD4F3CF);
const kNavInactive = Color(0xFFA7A3AD);
const kMagentaAppbarStart = Color(0xFF9C1E63);
const kSurfaceLowest = Color(0xFFFFFFFF);
const kSurfaceContainer = Color(0xFFEFEDEF);
const kSurfaceContainerHigh = Color(0xFFE9E8E9);

// Shadow base colour (rgba 40,20,40).
const _shadowInk = Color(0xFF281428);

List<BoxShadow> cardShadow({double opacity = 0.25}) => [
      BoxShadow(
        color: _shadowInk.withValues(alpha: opacity),
        blurRadius: 24,
        spreadRadius: -16,
        offset: const Offset(0, 10),
      ),
    ];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Diagonal gradient swatch (matches the prototype's `linear-gradient(140deg…)`).
LinearGradient swatch(Color a, Color b) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [a, b],
    );

/// Format a number as `1,350.00` (en-US grouping, 2 decimals).
String money(num n) {
  final s = n.toDouble().toStringAsFixed(2);
  final dot = s.indexOf('.');
  final intPart = s.substring(0, dot);
  final dec = s.substring(dot + 1);
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '${buf.toString()}.$dec';
}

/// Stable gradient placeholder for a product, keyed by its id/name.
const List<List<Color>> _palette = [
  [Color(0xFFEAD98A), Color(0xFFD3B94A)], // banana yellow
  [Color(0xFFE8A39C), Color(0xFFCF5A52)], // apple red
  [Color(0xFF84B06E), Color(0xFF4A7F3F)], // spinach green
  [Color(0xFFE6A56A), Color(0xFFCF7A31)], // carrot orange
  [Color(0xFFE08A8E), Color(0xFFC5414C)], // strawberry
  [Color(0xFF6FA06B), Color(0xFF2F5E2C)], // broccoli
  [Color(0xFFE08A6A), Color(0xFFC5504A)], // tomato
];

const Map<String, int> _keyPalette = {
  'bananas': 0,
  'apples': 1,
  'spinach': 2,
  'carrots': 3,
  'strawberries': 4,
  'broccoli': 5,
  'tomatoes': 6,
};

LinearGradient gradientFor(String key) {
  final idx = _keyPalette[key] ?? (key.hashCode.abs() % _palette.length);
  final pair = _palette[idx];
  return swatch(pair[0], pair[1]);
}

/// Transient bottom toast (≈1.7s) used for prototype actions.
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kInk,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
}

// ---------------------------------------------------------------------------
// Main tab index (shared between the shell and the Cart screen's bottom nav)
// ---------------------------------------------------------------------------
final mainTabProvider = StateProvider<int>((_) => 0);

// ---------------------------------------------------------------------------
// SRIBEES wordmark (italic, skewed, mirrored second "E")
// ---------------------------------------------------------------------------

class SribeesWordmark extends StatelessWidget {
  const SribeesWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.5,
      height: 1,
    );
    return Transform(
      transform: Matrix4.skewX(-0.035),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          const Text('SRIBE', style: style),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
            child: const Text('E', style: style),
          ),
          const Text('S', style: style),
          const SizedBox(width: 5),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'Online',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared magenta header (menu · wordmark · cart pill)
// ---------------------------------------------------------------------------

class SribeesHeader extends ConsumerWidget {
  final VoidCallback onMenu;
  final VoidCallback onCart;
  const SribeesHeader({super.key, required this.onMenu, required this.onCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final count = cart.itemCount;
    final total = cart.items.fold<double>(0, (s, i) => s + i.price * i.quantity);
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(18, topInset + 12, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.9, -0.5),
          end: Alignment(0.9, 0.5),
          colors: [kMagenta, kMagentaLight],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenu,
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          ),
          const Spacer(),
          const SribeesWordmark(),
          const Spacer(),
          _CartPill(count: count, total: total, onTap: onCart),
        ],
      ),
    );
  }
}

class _CartPill extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;
  const _CartPill(
      {required this.count, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 5, 11, 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white, size: 18),
                if (count > 0)
                  Positioned(
                    top: -6,
                    right: -7,
                    child: Container(
                      width: 15,
                      height: 15,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: kMagenta,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              'Rs${money(total)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart summary card (used on Saved & Orders tabs)
// ---------------------------------------------------------------------------

class CartSummaryCard extends ConsumerWidget {
  final VoidCallback onViewCart;
  const CartSummaryCard({super.key, required this.onViewCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final count = cart.itemCount;
    final total = cart.items.fold<double>(0, (s, i) => s + i.price * i.quantity);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow(opacity: 0.18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kMagentaTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                color: kMagenta, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count items in your cart',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. ${money(total)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kMagenta,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onViewCart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: kMagenta,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'View Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bottom nav (white, notched for the FAB)
// ---------------------------------------------------------------------------

class SribeesBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const SribeesBottomNav({
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: kCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 72,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NavItem(
                  icon: Icons.home_outlined,
                  label: 'HOME',
                  index: 0,
                  selected: selected,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.favorite_border_rounded,
                  label: 'SAVED',
                  index: 1,
                  selected: selected,
                  onTap: onTap),
              const SizedBox(width: 58), // FAB gap
              _NavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'ORDERS',
                  index: 2,
                  selected: selected,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'PROFILE',
                  index: 3,
                  selected: selected,
                  onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    final color = active ? kMagenta : kNavInactive;
    // Saved tab shows a filled heart when active (matches prototype).
    final displayIcon =
        (index == 1 && active) ? Icons.favorite_rounded : icon;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(displayIcon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sparkle FAB (magenta, white border, pulsing glow ring)
// ---------------------------------------------------------------------------

class SribeesSparkleFab extends StatefulWidget {
  final VoidCallback onTap;
  const SribeesSparkleFab({super.key, required this.onTap});

  @override
  State<SribeesSparkleFab> createState() => _SribeesSparkleFabState();
}

class _SribeesSparkleFabState extends State<SribeesSparkleFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _glow,
              builder: (_, __) {
                final t = _glow.value;
                final scale = 1.0 + 0.32 * t;
                final opacity = (0.35 * (1 - t)).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kMagenta.withValues(alpha: opacity),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kMagenta,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: kMagenta.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 25),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable bits
// ---------------------------------------------------------------------------

/// "10% Cash Back" corner badge (top-left, rounded bottom-right).
class CashBackBadge extends StatelessWidget {
  const CashBackBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: const BoxDecoration(
        color: kMagenta,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
      ),
      child: const Text(
        '10% Cash Back',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// "10% CASH BACK" pill (magenta, used on the product price block).
class CashBackPill extends StatelessWidget {
  const CashBackPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: kMagenta,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '10% CASH BACK',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Secondary-screen magenta app bar (back · title · optional trailing)
// ---------------------------------------------------------------------------

class SribeesAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;
  final bool centerTitle;
  const SribeesAppBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.9, -0.5),
          end: Alignment(0.9, 0.5),
          colors: [kMagentaAppbarStart, kMagenta],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              textAlign: centerTitle ? TextAlign.center : TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 22),
        ],
      ),
    );
  }
}

/// From a pushed secondary screen, switch the main tab and return to the shell.
void popToTab(BuildContext context, WidgetRef ref, int index) {
  ref.read(mainTabProvider.notifier).state = index;
  Navigator.of(context).popUntil((r) => r.isFirst);
}
