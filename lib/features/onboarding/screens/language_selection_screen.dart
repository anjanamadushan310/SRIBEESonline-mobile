/// SRIBEESonline - Language Selection Screen
///
/// Displays three large, clean buttons — one for each supported language:
///   - සිංහල  (Sinhala)
///   - தமிழ்   (Tamil)
///   - English
///
/// On tap the selection is persisted to SharedPreferences (via
/// [LanguageNotifier]) and the app navigates to [AddressSelectionScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/providers/language_provider.dart';
import 'phone_login_screen.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Branding ──
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.translate_rounded,
                  size: 44,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Choose your language',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'භාෂාව තෝරන්න · மொழியைத் தேர்ந்தெடுக்கவும்',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Language buttons ──
              _LanguageButton(
                label: 'සිංහල',
                subtitle: 'Sinhala',
                code: 'si',
                icon: '🇱🇰',
                onTap: () => _select(context, ref, 'si'),
              ),
              const SizedBox(height: 16),

              _LanguageButton(
                label: 'தமிழ்',
                subtitle: 'Tamil',
                code: 'ta',
                icon: '🇱🇰',
                onTap: () => _select(context, ref, 'ta'),
              ),
              const SizedBox(height: 16),

              _LanguageButton(
                label: 'English',
                subtitle: 'English',
                code: 'en',
                icon: '🌐',
                onTap: () => _select(context, ref, 'en'),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    await ref.read(languageProvider.notifier).setLanguage(code);

    if (!context.mounted) return;
    pushReplacementFade(context, const PhoneLoginScreen());
  }
}

// ===========================================================================
// Private: Language button widget
// ===========================================================================

class _LanguageButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final String code;
  final String icon;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.subtitle,
    required this.code,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(color: primary.withOpacity(0.25), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    if (label != subtitle)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
