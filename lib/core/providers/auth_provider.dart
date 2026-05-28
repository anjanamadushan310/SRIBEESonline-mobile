/// SRIBEESonline - Authentication Provider
///
/// Riverpod state management for authentication.
/// Handles login, registration, token refresh, and user state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'language_provider.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/repositories/auth_repository.dart';

/// Authentication state (sealed-style without freezed).
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  final String? message;
  const AuthUnauthenticated([this.message]);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Extension to provide maybeWhen-style API.
extension AuthStateX on AuthState {
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(User user)? authenticated,
    T Function(String? message)? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      AuthInitial() => (initial ?? orElse)(),
      AuthLoading() => (loading ?? orElse)(),
      AuthAuthenticated(:final user) => authenticated != null ? authenticated(user) : orElse(),
      AuthUnauthenticated(:final message) => unauthenticated != null ? unauthenticated(message) : orElse(),
      AuthError(:final message) => error != null ? error(message) : orElse(),
    };
  }
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  return AuthRepository(apiClient, prefs);
});

/// Auth state notifier provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(repository, apiClient);
});

/// Current user provider (convenience accessor)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final ApiClient _apiClient;

  AuthNotifier(this._repository, this._apiClient) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  /// Check initial auth status from stored tokens
  Future<void> _checkAuthStatus() async {
    state = const AuthLoading();
    
    try {
      final tokens = await _repository.getStoredTokens();
      
      if (tokens != null) {
        _apiClient.setTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        
        // Verify token and get user
        final user = await _repository.getCurrentUser();
        if (user != null) {
          state = AuthAuthenticated(user);
          return;
        }
      }
      
      state = const AuthUnauthenticated();
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    
    try {
      final result = await _repository.login(
        email: email,
        password: password,
      );
      
      _apiClient.setTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      
      await _repository.storeTokens(result);
      
      state = AuthAuthenticated(result.user);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Login failed. Please try again.');
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    state = const AuthLoading();
    
    try {
      final result = await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      
      _apiClient.setTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      
      await _repository.storeTokens(result);
      
      state = AuthAuthenticated(result.user);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Registration failed. Please try again.');
    }
  }

  /// Development-only: set authenticated state without backend (e.g. mock OTP).
  /// Use for temporary mock login until Notify.lk or real SMS is integrated.
  void setMockAuthenticated(User user) {
    state = AuthAuthenticated(user);
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      _apiClient.clearTokens();
      await _repository.clearStoredTokens();
      state = const AuthUnauthenticated();
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      await _repository.forgotPassword(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final currentUser = state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    
    if (currentUser == null) return;
    
    try {
      final updatedUser = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      
      state = AuthAuthenticated(updatedUser);
    } on ApiException catch (e) {
      // Keep current state, throw error for UI handling
      throw e;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
