/// SRIBEESonline - Phone OTP Verification Provider (Module 1.7)
///
/// Thin wrapper over the backend OTP endpoints for the authenticated user:
///   POST /api/v1/auth/request-otp  -> generate + 'send' a 6-digit code
///   POST /api/v1/auth/verify-otp   -> validate the code, mark phone verified
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

class OtpService {
  final ApiClient _api;
  const OtpService(this._api);

  /// Ask the backend to generate + dispatch a fresh OTP. Returns the code's
  /// validity window in seconds (for the resend countdown).
  Future<int> requestOtp() async {
    final res = await _api.post<Map<String, dynamic>>('/auth/request-otp');
    final expires = res['expiresInSeconds'] ?? res['expires_in_seconds'];
    return (expires is num) ? expires.toInt() : 180;
  }

  /// Verify a 6-digit code. Returns true when the phone is now verified.
  /// Throws [ApiException] with a friendly message on an invalid/expired code.
  Future<bool> verifyOtp(String code) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {'code': code},
    );
    return res['isPhoneVerified'] == true ||
        res['is_phone_verified'] == true ||
        res['success'] == true;
  }
}

final otpServiceProvider = Provider<OtpService>((ref) {
  return OtpService(ref.watch(apiClientProvider));
});
