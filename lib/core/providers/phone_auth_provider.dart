/// SRIBEESonline - Phone Auth Verification State
///
/// Holds [verificationId] and [resendToken] from Firebase
/// [verifyPhoneNumber] for use on the OTP screen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for phone verification (after verifyPhoneNumber, before signInWithCredential).
class PhoneVerificationState {
  const PhoneVerificationState({
    this.verificationId,
    this.resendToken,
    this.phoneNumber,
  });

  final String? verificationId;
  final int? resendToken;
  final String? phoneNumber;

  bool get isReady => verificationId != null && verificationId!.isNotEmpty;
}

/// Provider for phone verification state (verificationId, resendToken, phoneNumber).
final phoneVerificationProvider =
    StateNotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>(
        (ref) => PhoneVerificationNotifier());

class PhoneVerificationNotifier extends StateNotifier<PhoneVerificationState> {
  PhoneVerificationNotifier() : super(const PhoneVerificationState());

  void setVerification({
    required String verificationId,
    int? resendToken,
    String? phoneNumber,
  }) {
    state = PhoneVerificationState(
      verificationId: verificationId,
      resendToken: resendToken,
      phoneNumber: phoneNumber,
    );
  }

  void clear() {
    state = const PhoneVerificationState();
  }
}
