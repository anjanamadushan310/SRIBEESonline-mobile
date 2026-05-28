/// SRIBEESonline - Phone Login Screen
///
/// Shown after [LanguageSelectionScreen] for new users.
/// Temporary mock: "Send Verification Code" navigates to [OTPScreen] without
/// Firebase; use OTP 1234 to simulate login. UI unchanged for future Notify.lk.
/// "Continue as Guest" → [AddressSelectionScreen].
///
/// All copy is localized via [languageProvider] (en, si, ta).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/phone_auth_provider.dart';
import 'address_selection_screen.dart';
import 'otp_screen.dart';

// ---------------------------------------------------------------------------
// SRIBEES maroon theme
// ---------------------------------------------------------------------------
const _maroonPrimary = Color(0xFF6B2D5C);

// ---------------------------------------------------------------------------
// Localized strings by language code
// ---------------------------------------------------------------------------

const _copy = {
  'en': (
    title: "What's your phone number?",
    sendCode: 'Send Verification Code',
    continueAsGuest: 'Not now? Continue as Guest',
    errorInvalidPhone: 'Enter a valid 9-digit Sri Lanka mobile number',
    errorSendCode: 'Failed to send code. Please try again.',
    sending: 'Sending…',
  ),
  'si': (
    title: 'ඔබේ දුරකථන අංකය කුමක්ද?',
    sendCode: 'තහවුරු කිරීමේ කේතය එවන්න',
    continueAsGuest: 'පසුව? ආගන්තුකයෙකු ලෙස ඉදිරියට යන්න',
    errorInvalidPhone: 'වලංගු 9-ඉලක්කම් ලංකා ජංගම අංකයක් ඇතුළත් කරන්න',
    errorSendCode: 'කේතය යැවීම අසාර්ථක විය. නැවත උත්සාහ කරන්න.',
    sending: 'යවමින්…',
  ),
  'ta': (
    title: 'உங்கள் தொலைபேசி எண் என்ன?',
    sendCode: 'சரிபார்ப்புக் குறியீட்டை அனுப்பவும்',
    continueAsGuest: 'இப்போது இல்லையா? விருந்தினராகத் தொடரவும்',
    errorInvalidPhone: 'செல்லுபடியான 9 இலக்க இலங்கை மொபைல் எண்ணை உள்ளிடவும்',
    errorSendCode: 'குறியீட்டை அனுப்புவது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
    sending: 'அனுப்புகிறது…',
  ),
};

bool _isValidSriLankaPhone(String digits) {
  if (digits.length != 9) return false;
  if (!RegExp(r'^[0-9]{9}$').hasMatch(digits)) return false;
  return digits.startsWith('7');
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _errorText = '';
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _t(String? code, String key) {
    final k = code ?? 'en';
    final c = _copy[k] ?? _copy['en']!;
    switch (key) {
      case 'title':
        return c.title;
      case 'sendCode':
        return c.sendCode;
      case 'continueAsGuest':
        return c.continueAsGuest;
      case 'errorInvalidPhone':
        return c.errorInvalidPhone;
      case 'errorSendCode':
        return c.errorSendCode;
      case 'sending':
        return c.sending;
      default:
        return c.title;
    }
  }

  Future<void> _onSendCode() async {
    final raw = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = raw.length > 9 ? raw.substring(raw.length - 9) : raw;

    setState(() => _errorText = '');

    if (!_isValidSriLankaPhone(digits)) {
      final langCode = ref.read(languageProvider)?.languageCode ?? 'en';
      setState(() => _errorText = _t(langCode, 'errorInvalidPhone'));
      return;
    }

    final fullPhone = '+94$digits';
    ref.read(phoneVerificationProvider.notifier).setVerification(
          verificationId: 'mock',
          phoneNumber: fullPhone,
        );
    if (!mounted) return;
    pushReplacementFade(context, const OTPScreen());
  }

  void _onContinueAsGuest() {
    ref.read(phoneVerificationProvider.notifier).clear();
    pushReplacementFade(context, const AddressSelectionScreen());
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final langCode = locale?.languageCode ?? 'en';
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _maroonPrimary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        size: 40,
                        color: _maroonPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _t(langCode, 'title'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _SriLankaPhoneField(
                    controller: _controller,
                    focusNode: _focusNode,
                    errorText: _errorText,
                    onChanged: (_) => setState(() => _errorText = ''),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onSendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _maroonPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _maroonPrimary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_t(langCode, 'sendCode')),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _loading ? null : _onContinueAsGuest,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Text(_t(langCode, 'continueAsGuest')),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        if (_loading)
          Positioned.fill(
            child: ModalBarrier(
              color: Colors.black26,
              dismissible: false,
            ),
          ),
        if (_loading)
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_t(langCode, 'sending')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Phone input field
// ---------------------------------------------------------------------------

class _SriLankaPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String errorText;
  final ValueChanged<String> onChanged;

  const _SriLankaPhoneField({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText.isNotEmpty ? Colors.red.shade300 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇱🇰', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  '+94',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: '7X XXX XXXX',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                errorText: errorText.isEmpty ? null : errorText,
                errorStyle: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
