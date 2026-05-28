/// SRIBEESonline - Auth Repository
///
/// Handles login, register, token storage, and profile via backend API.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../models/user_model.dart';

const _keyAccessToken = 'auth_access_token';
const _keyRefreshToken = 'auth_refresh_token';

/// Stored tokens for persistence.
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });
}

/// Result of login (and optionally register if backend returns tokens).
class AuthResult {
  final User user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthRepository {
  final ApiClient _api;
  final SharedPreferences _prefs;

  AuthRepository(this._api, this._prefs);

  /// Read stored tokens from disk.
  Future<AuthTokens?> getStoredTokens() async {
    final access = _prefs.getString(_keyAccessToken);
    final refresh = _prefs.getString(_keyRefreshToken);
    if (access == null || access.isEmpty) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh ?? '');
  }

  /// Persist tokens.
  Future<void> storeTokens(AuthResult result) async {
    await _prefs.setString(_keyAccessToken, result.accessToken);
    await _prefs.setString(_keyRefreshToken, result.refreshToken);
  }

  /// Clear stored tokens.
  Future<void> clearStoredTokens() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
  }

  /// GET /auth/me — current user profile.
  Future<User?> getCurrentUser() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/auth/me');
      final userJson = res['user'];
      if (userJson == null) return null;
      return User.fromJson(Map<String, dynamic>.from(userJson as Map));
    } catch (_) {
      return null;
    }
  }

  /// POST /auth/login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'remember_me': false,
      },
    );
    final user = User.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    final tokens = res['tokens'] as Map<String, dynamic>;
    return AuthResult(
      user: user,
      accessToken: tokens['accessToken'] as String? ?? tokens['access_token'] as String? ?? '',
      refreshToken: tokens['refreshToken'] as String? ?? tokens['refresh_token'] as String? ?? '',
    );
  }

  /// POST /auth/register — backend may not return tokens until email verified.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'full_name': '$firstName $lastName'.trim(),
        if (phone.isNotEmpty) 'phone': phone,
      },
    );
    final user = User.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    final tokens = res['tokens'] as Map<String, dynamic>?;
    return AuthResult(
      user: user,
      accessToken: tokens?['accessToken'] as String? ?? tokens?['access_token'] as String? ?? '',
      refreshToken: tokens?['refreshToken'] as String? ?? tokens?['refresh_token'] as String? ?? '',
    );
  }

  /// POST /auth/logout (optional); clears tokens locally either way.
  Future<void> logout() async {
    try {
      await _api.post<Map<String, dynamic>>('/auth/logout');
    } catch (_) {}
    await clearStoredTokens();
  }

  /// POST /auth/forgot-password
  Future<void> forgotPassword(String email) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  /// PATCH /auth/me or PUT profile
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (phone != null) data['phone'] = phone;
    if (avatarUrl != null) data['profile_picture_url'] = avatarUrl;
    final res = await _api.patch<Map<String, dynamic>>('/auth/me', data: data);
    final userJson = res['user'] ?? res;
    return User.fromJson(Map<String, dynamic>.from(userJson as Map));
  }

  /// POST /auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }
}
