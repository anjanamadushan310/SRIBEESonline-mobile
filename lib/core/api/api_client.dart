/// SRIBEESonline - API Client Service
///
/// Dio-based HTTP client with interceptors for authentication,
/// error handling, and request/response logging.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../providers/device_id_provider.dart';

/// API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final deviceId = ref.watch(deviceIdProvider);
  return ApiClient(deviceId: deviceId);
});

/// API exception with structured error data
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.errors,
  });

  @override
  String toString() => message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isNetworkError => statusCode == null;
}

/// Main API client class
class ApiClient {
  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  final String? _deviceId;

  ApiClient({String? deviceId}) : _deviceId = deviceId {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // In development mode, tell the backend we're on the Android emulator so
    // it rewrites MinIO URLs from localhost → 10.0.2.2.
    if (AppConfig.isDevelopment && defaultTargetPlatform == TargetPlatform.android) {
      headers['X-Client-Platform'] = 'android-emulator';
    }

    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: headers,
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Auth interceptor (and X-Device-Id for guest)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        } else if (_deviceId != null) {
          options.headers['X-Device-Id'] = _deviceId;
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          // Try to refresh token
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // Retry the request
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $_accessToken';
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));

    // Logging interceptor (debug only)
    if (AppConfig.isDevelopment) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (o) => print('🌐 API: $o'),
      ));
    }

    // Retry interceptor for network errors
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error)) {
          try {
            await Future.delayed(const Duration(seconds: 1));
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.error is SocketException);
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await Dio().post(
        '${AppConfig.instance.apiBaseUrl}/api/v1/auth/refresh',
        data: {'refresh_token': _refreshToken},
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        _refreshToken = response.data['refresh_token'];
        return true;
      }
    } catch (e) {
      // Refresh failed - clear tokens
      _accessToken = null;
      _refreshToken = null;
    }
    return false;
  }

  /// Set authentication tokens
  void setTokens({required String accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Clear authentication tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  // =========================================================================
  // HTTP Methods
  // =========================================================================

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return parser != null ? parser(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return parser != null ? parser(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return parser != null ? parser(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return parser != null ? parser(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> upload<T>(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
    T Function(dynamic)? parser,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?extraFields,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );

      return parser != null ? parser(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    final response = e.response;

    if (response != null) {
      final data = response.data;
      String message = 'An error occurred';
      String? errorCode;
      Map<String, dynamic>? errors;

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['detail'] ?? message;
        errorCode = data['error_code'];
        errors = data['errors'];
      }

      return ApiException(
        message: message,
        statusCode: response.statusCode,
        errorCode: errorCode,
        errors: errors,
      );
    }

    // Network errors
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        return ApiException(message: 'No internet connection.');
      default:
        return ApiException(message: 'Network error. Please try again.');
    }
  }
}
