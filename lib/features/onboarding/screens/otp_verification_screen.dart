/// SRIBEESonline - Phone OTP Verification (Module 1.7)
///
/// Shown after registration to verify the user's phone number against the
/// backend (POST /auth/request-otp + /auth/verify-otp) before they reach the
/// main app. A 6-digit code field + a "Resend Code" countdown.
/// On success → continues into the location gatekeeper (AddressSelectionScreen).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/otp_provider.dart';
import 'address_selection_screen.dart';

const _maroon = Color(0xFF6B2D5C);
const _green = Color(0xFF2D5C4A);
const _resendCooldown = 30; // seconds before "Resend Code" re-enables

class OtpVerificationScreen extends ConsumerStatefulWidget {
  /// Optional phone (for the "sent to …" subtitle).
  final String? phone;
  const OtpVerificationScreen({super.key, this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _codeCtrl = TextEditingController();
  final _focus = FocusNode();

  bool _requesting = false;
  bool _verifying = false;
  String? _error;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-request a code as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestCode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _code => _codeCtrl.text.trim();

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _requestCode() async {
    if (_requesting) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      await ref.read(otpServiceProvider).requestOtp();
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not send the code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _verify() async {
    if (_verifying || _code.length != 6) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final ok = await ref.read(otpServiceProvider).verifyOtp(_code);
      if (!ok) {
        setState(() {
          _verifying = false;
          _error = 'Invalid or expired code. Please try again.';
        });
        return;
      }
      if (!mounted) return;
      // Phone verified → proceed into the delivery-location gatekeeper.
      pushAndClearFade(context, const AddressSelectionScreen());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Verification failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft == 0 && !_requesting;
    final subtitle = (widget.phone != null && widget.phone!.isNotEmpty)
        ? 'We sent a 6-digit code to ${widget.phone}.'
        : 'We sent a 6-digit code to your phone.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Phone'),
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sms_outlined, size: 44, color: _maroon),
              const SizedBox(height: 18),
              Text(
                'Enter verification code',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _maroon,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),

              // Hidden field captures the 6 digits; the boxes below mirror it.
              _codeBoxes(),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: TextStyle(color: Colors.red[700], fontSize: 13)),
              ],

              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_code.length == 6 && !_verifying) ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _green.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: canResend
                    ? TextButton(
                        onPressed: _requestCode,
                        child: const Text('Resend Code',
                            style: TextStyle(
                                color: _maroon, fontWeight: FontWeight.w700)),
                      )
                    : Text(
                        _requesting
                            ? 'Sending…'
                            : 'Resend code in ${_secondsLeft}s',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeBoxes() {
    return Stack(
      children: [
        // The visible 6 boxes.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            final filled = i < _code.length;
            final isNext = i == _code.length;
            return Container(
              width: 46,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (filled || isNext) ? _maroon : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: Text(
                filled ? _code[i] : '',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _maroon),
              ),
            );
          }),
        ),
        // Transparent field on top actually receives input; tapping focuses it.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _codeCtrl,
              focusNode: _focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) {
                setState(() {}); // refresh boxes + button state
                if (_code.length == 6) _verify();
              },
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
            ),
          ),
        ),
      ],
    );
  }
}
