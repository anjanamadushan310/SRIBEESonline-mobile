/// SRIBEESonline - Base Repository
///
/// Abstract base class for repositories implementing the repository pattern.
/// Provides common functionality for API calls and caching.
library;

import 'dart:async';

import '../api/api_client.dart';

/// Result wrapper for API responses
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result.success(this.data)
      : error = null,
        isSuccess = true;

  Result.failure(this.error)
      : data = null,
        isSuccess = false;

  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    }
    return failure(error ?? 'Unknown error');
  }
}

/// Paginated response wrapper
class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  }) : hasMore = (page * pageSize) < total;

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = (json['items'] as List?)
            ?.map((e) => fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PaginatedResult(
      items: items,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
    );
  }
}

/// Base repository with common functionality
abstract class BaseRepository {
  final ApiClient apiClient;

  BaseRepository(this.apiClient);

  /// Wrap API call with error handling
  Future<Result<T>> safeCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Result.success(result);
    } on ApiException catch (e) {
      return Result.failure(e.message);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Wrap API call with caching
  Future<T> cachedCall<T>({
    required String cacheKey,
    required Future<T> Function() apiCall,
    required T Function(String) fromCache,
    required String Function(T) toCache,
    Duration cacheDuration = const Duration(minutes: 5),
    T? Function()? fallback,
  }) async {
    // Try cache first (implement with Hive in production)
    // final cached = await _getFromCache(cacheKey);
    // if (cached != null) return fromCache(cached);

    try {
      final result = await apiCall();
      // await _saveToCache(cacheKey, toCache(result), cacheDuration);
      return result;
    } catch (e) {
      if (fallback != null) {
        final fb = fallback();
        if (fb != null) return fb;
      }
      rethrow;
    }
  }
}

/// Mixin for offline-capable repositories
mixin OfflineCapable {
  /// Queue for pending operations when offline
  final List<PendingOperation> _pendingOperations = [];

  /// Add operation to pending queue
  void queueOperation(PendingOperation operation) {
    _pendingOperations.add(operation);
  }

  /// Process pending operations
  Future<void> processPendingOperations() async {
    final operations = List<PendingOperation>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final op in operations) {
      try {
        await op.execute();
      } catch (e) {
        // Re-queue failed operations
        _pendingOperations.add(op);
      }
    }
  }

  /// Check if there are pending operations
  bool get hasPendingOperations => _pendingOperations.isNotEmpty;
}

/// Pending operation for offline sync
class PendingOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final Future<void> Function() execute;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.execute,
  }) : createdAt = DateTime.now();
}
