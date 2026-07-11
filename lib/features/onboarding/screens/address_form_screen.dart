/// SRIBEESonline - Address Form Screen
///
/// Single form with Province → District → Post Office cascading dropdowns
/// plus address lines.
///
/// Authenticated users: the address is persisted via the backend Address CRUD
/// (POST /user/addresses, PUT /user/addresses/{id}, DELETE in edit mode) and
/// the screen pops with `true` so the caller can refresh its list.
/// Guests: falls back to POST /branch/resolve-by-location and navigates Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/branch_provider.dart';
import '../../home/screens/home_screen.dart';
import '../widgets/location_cascade_selector.dart';

// Maroon / Green grocery theme
const _maroon = Color(0xFF6B2D5C);
const _green = Color(0xFF2D5C4A);

class AddressFormScreen extends ConsumerStatefulWidget {
  /// Non-null in edit mode — the backend address_id being edited.
  final String? addressId;

  /// Optional initial values for edit mode.
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialPostOffice;
  final String? initialAddressLine1;
  final String? initialAddressLine2;

  const AddressFormScreen({
    super.key,
    this.addressId,
    this.initialProvince,
    this.initialDistrict,
    this.initialPostOffice,
    this.initialAddressLine1,
    this.initialAddressLine2,
  });

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedPostOffice;
  String? _servingBranchName;

  bool _submitting = false;
  bool _deleting = false;
  String? _error;

  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;

  bool get _isEditMode => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    // In edit mode these seed the cascade. LocationCascadeSelector fetches each
    // level and drops a selection that is no longer covered, so a stale value
    // degrades to "please re-pick" instead of crashing the dropdown.
    _selectedProvince = widget.initialProvince;
    _selectedDistrict = widget.initialDistrict;
    _selectedPostOffice = widget.initialPostOffice;
    _addressLine1Controller =
        TextEditingController(text: widget.initialAddressLine1 ?? '');
    _addressLine2Controller =
        TextEditingController(text: widget.initialAddressLine2 ?? '');
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final province = _selectedProvince?.trim();
    final district = _selectedDistrict?.trim();
    final postOffice = _selectedPostOffice?.trim();
    if (province == null || province.isEmpty || district == null || district.isEmpty || postOffice == null || postOffice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Province, District and Post Office.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isAuth = ref.read(isAuthenticatedProvider);
    if (isAuth) {
      await _saveAddress(
        province: province,
        district: district,
        postOffice: postOffice,
      );
    } else {
      await _resolveBranchAsGuest(
        province: province,
        district: district,
        postOffice: postOffice,
      );
    }
  }

  /// Authenticated flow: persist via the backend Address CRUD, then pop with
  /// `true` so the address list refreshes.
  Future<void> _saveAddress({
    required String province,
    required String district,
    required String postOffice,
  }) async {
    final line1 = _addressLine1Controller.text.trim();
    if (line1.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Address Line 1.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final line2 = _addressLine2Controller.text.trim();
    final payload = <String, dynamic>{
      'address_line1': line1,
      'address_line2': line2.isEmpty ? null : line2,
      'province': province,
      'district': district,
      'post_office': postOffice,
    };

    try {
      final api = ref.read(apiClientProvider);
      if (_isEditMode) {
        await api.put<Map<String, dynamic>>(
          '/user/addresses/${widget.addressId}',
          data: payload,
        );
      } else {
        await api.post<Map<String, dynamic>>(
          '/user/addresses',
          data: payload,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Address updated.' : 'Address saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      _showError('Could not save the address. Please try again.');
      setState(() => _submitting = false);
    }
  }

  /// Guest flow: no persistence — resolve the serving branch and go Home.
  Future<void> _resolveBranchAsGuest({
    required String province,
    required String district,
    required String postOffice,
  }) async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final notifier = ref.read(branchProvider.notifier);
      final branch = await notifier.resolveFromLocation(
        province: province,
        district: district,
        postOffice: postOffice,
      );
      if (!mounted) return;
      pushAndClearFade(context, HomeScreen(branchName: branch.branchName));
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      _showError('Could not resolve branch. Please try another area.');
      setState(() => _submitting = false);
    }
  }

  Future<void> _deleteAddress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address?'),
        content: const Text('This address will be removed from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/user/addresses/${widget.addressId}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showError('Could not delete the address. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Address' : 'Delivery Address'),
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete address',
              onPressed: (_deleting || _submitting) ? null : _deleteAddress,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[800]))),
                  ],
                ),
              ),
            ],
            Text(
              'Select your delivery area',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _maroon,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Province → District → Post Office',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Live Province → District → Post Office cascade.
            LocationCascadeSelector(
              selectedProvince: _selectedProvince,
              selectedDistrict: _selectedDistrict,
              selectedPostOffice: _selectedPostOffice,
              enabled: !_submitting && !_deleting,
              decorationBuilder: _inputDecoration,
              // Changing a level invalidates everything below it — a district
              // from the old province would resolve to the wrong branch.
              onProvinceChanged: (v) => setState(() {
                _selectedProvince = v;
                _selectedDistrict = null;
                _selectedPostOffice = null;
                _servingBranchName = null;
              }),
              onDistrictChanged: (v) => setState(() {
                _selectedDistrict = v;
                _selectedPostOffice = null;
                _servingBranchName = null;
              }),
              onPostOfficeChanged: (po, branchName) => setState(() {
                _selectedPostOffice = po;
                _servingBranchName = branchName;
              }),
            ),
            if (_servingBranchName != null && _servingBranchName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: _green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivered by $_servingBranchName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Address lines (persisted for authenticated users)
            TextFormField(
              controller: _addressLine1Controller,
              decoration: _inputDecoration('Address Line 1 (Street/House No)'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: _inputDecoration('Address Line 2 (Locality/Village)'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditMode ? 'Save Changes' : 'Confirm & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _maroon, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
