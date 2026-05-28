/// SRIBEESonline - Branch Provider
///
/// Riverpod state management for the user's active branch context.
/// After the user selects an address, the backend resolves which branch
/// serves that area.  The result is stored both in-memory (for this
/// session) and in SharedPreferences (for the splash-screen fast-path).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import 'language_provider.dart'; // for sharedPrefsProvider

// ---------------------------------------------------------------------------
// Branch context model
// ---------------------------------------------------------------------------
class BranchContext {
  final String branchId;
  final String branchName;
  final String? province;
  final String? district;
  final String? postOffice;

  const BranchContext({
    required this.branchId,
    required this.branchName,
    this.province,
    this.district,
    this.postOffice,
  });

  factory BranchContext.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return BranchContext(
      branchId: (data['branch_id'] ?? data['branchId'] ?? '').toString(),
      branchName: data['branch_name'] ?? data['branchName'] ?? '',
      province: data['province'],
      district: data['district'],
      postOffice: data['post_office'] ?? data['postOffice'],
    );
  }

  Map<String, dynamic> toJson() => {
        'branch_id': branchId,
        'branch_name': branchName,
        'province': province,
        'district': district,
        'post_office': postOffice,
      };
}

// ---------------------------------------------------------------------------
// Branch provider
// ---------------------------------------------------------------------------
final branchProvider =
    StateNotifierProvider<BranchNotifier, BranchContext?>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  final api = ref.watch(apiClientProvider);
  return BranchNotifier(prefs, api);
});

/// Convenience: true when a branch has been resolved for this session.
final hasBranchProvider = Provider<bool>((ref) {
  return ref.watch(branchProvider) != null;
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class BranchNotifier extends StateNotifier<BranchContext?> {
  static const _keyId = 'branch_id';
  static const _keyName = 'branch_name';

  final SharedPreferences _prefs;
  final ApiClient _api;

  BranchNotifier(this._prefs, this._api) : super(null) {
    _loadSaved();
  }

  void _loadSaved() {
    final id = _prefs.getString(_keyId);
    final name = _prefs.getString(_keyName);
    if (id != null && id.isNotEmpty) {
      state = BranchContext(branchId: id, branchName: name ?? '');
    }
  }

  /// Call `POST /branch/resolve` with the selected address and persist.
  Future<BranchContext> resolveFromAddress(String addressId) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/branch/resolve',
      data: {'address_id': addressId},
    );

    final branch = BranchContext.fromJson(response);
    await _persist(branch);
    state = branch;
    return branch;
  }

  /// Call `POST /branch/resolve-by-location` with province, district, post_office.
  /// Used for guest users and when adding a new address from the form.
  Future<BranchContext> resolveFromLocation({
    required String province,
    required String district,
    required String postOffice,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/branch/resolve-by-location',
      data: {
        'province': province,
        'district': district,
        'post_office': postOffice,
      },
    );

    final branch = BranchContext.fromJson(response);
    await _persist(branch);
    state = branch;
    return branch;
  }

  /// Manually set branch (e.g. from cached data).
  Future<void> setBranch(BranchContext branch) async {
    await _persist(branch);
    state = branch;
  }

  /// Clear active branch (forces re-selection).
  Future<void> clear() async {
    await _prefs.remove(_keyId);
    await _prefs.remove(_keyName);
    state = null;
  }

  Future<void> _persist(BranchContext branch) async {
    await _prefs.setString(_keyId, branch.branchId);
    await _prefs.setString(_keyName, branch.branchName);
  }
}
