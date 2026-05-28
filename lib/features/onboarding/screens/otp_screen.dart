/// SRIBEESonline - OTP Verification Screen
///
/// Temporary mock: valid OTP is 1234. On success → set auth state and
/// navigate to [AddressSelectionScreen]. UI unchanged for future Notify.lk.
/// All strings localized via [languageProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/phone_auth_provider.dart';
import '../../../features/auth/models/user_model.dart';
import 'address_selection_screen.dart';

const _maroon = Color(0xFF6B2D5C);

// ---------------------------------------------------------------------------
// Localized strings (en, si, ta)
// ---------------------------------------------------------------------------

const _otpCopy = {
  'en': (
    title: 'Enter verification code',
    subtitle: 'We sent a 6-digit code to your phone.',
    verify: 'Verify',
    errorInvalidOtp: 'Please enter all 6 digits',
    errorVerifyFailed: 'Verification failed. Please check the code and try again.',
    verifying: 'Verifying…',
  ),
  'si': (
    title: 'තහවුරු කිරීමේ කේතය ඇතුළත් කරන්න',
    subtitle: 'අපි ඔබේ දුරකථනයට 6-ඉලක්කම් කේතයක් යවා ඇත.',
    verify: 'තහවුරු කරන්න',
    errorInvalidOtp: 'කරුණාකර ඉලක්කම් 6 ඇතුළත් කරන්න',
    errorVerifyFailed: 'තහවුරු කිරීම අසාර්ථක විය. කේතය පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
    verifying: 'තහවුරු කරමින්…',
  ),
  'ta': (
    title: 'சரிபார்ப்புக் குறியீட்டை உள்ளிடவும்',
    subtitle: 'உங்கள் தொலைபேசிக்கு 6 இலக்க குறியீட்டை அனுப்பினோம்.',
    verify: 'சரிபார்க்கவும்',
    errorInvalidOtp: 'அனைத்து 6 இலக்கங்களையும் உள்ளிடவும்',
    errorVerifyFailed: 'சரிபார்ப்பு தோல்வியடைந்தது. குறியீட்டை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
    verifying: 'சரிபார்க்கிறது…',
  ),
};

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({super.key});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _t(String? code, String key) {
    final k = code ?? 'en';
    final c = _otpCopy[k] ?? _otpCopy['en']!;
    switch (key) {
      case 'title':
        return c.title;
      case 'subtitle':
        return c.subtitle;
      case 'verify':
        return c.verify;
      case 'errorInvalidOtp':
        return c.errorInvalidOtp;
      case 'errorVerifyFailed':
        return c.errorVerifyFailed;
      case 'verifying':
        return c.verifying;
      default:
        return c.title;
    }
  }

  Future<void> _onVerify() async {
    final code = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final langCode = ref.read(languageProvider)?.languageCode ?? 'en';

    setState(() => _errorText = null);

    if (code.length < 4) {
      setState(() => _errorText = _t(langCode, 'errorInvalidOtp'));
      return;
    }

    setState(() => _loading = true);

    // Temporary mock OTP for development (replace with Notify.lk / real SMS later).
    const mockOtp = '1234';
    if (code == mockOtp) {
      ref.read(authProvider.notifier).setMockAuthenticated(User.mockUser);
      ref.read(phoneVerificationProvider.notifier).clear();
      if (!mounted) return;
      setState(() => _loading = false);
      pushAndClearFade(context, const AddressSelectionScreen());
      return;
    }

    setState(() {
      _loading = false;
      _errorText = _t(langCode, 'errorVerifyFailed');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t(langCode, 'errorVerifyFailed')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[700],
      ),
    );
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
          appBar: AppBar(
            title: Text(_t(langCode, 'title')),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Icon(
                      Icons.sms_outlined,
                      size: 64,
                      color: _maroon.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _t(langCode, 'subtitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() => _errorText = null),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      errorText: _errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _maroon,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _maroon.withOpacity(0.5),
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
                          : Text(_t(langCode, 'verify')),
                    ),
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
                    Text(_t(langCode, 'verifying')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
