/// SRIBEESonline - Address Form Screen
///
/// Single form with Province → District → Post Office cascading dropdowns.
/// On submit calls POST /branch/resolve-by-location and navigates to Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/locations_api.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/branch_provider.dart';
import '../../home/screens/home_screen.dart';

// Maroon / Green grocery theme
const _maroon = Color(0xFF6B2D5C);
const _green = Color(0xFF2D5C4A);

class AddressFormScreen extends ConsumerStatefulWidget {
  /// Optional initial values for edit mode (e.g. province, district, postOffice).
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialPostOffice;

  const AddressFormScreen({
    super.key,
    this.initialProvince,
    this.initialDistrict,
    this.initialPostOffice,
  });

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  List<ProvinceItem> _provinces = [];
  List<DistrictItem> _districts = [];
  List<PostOfficeItem> _postOffices = [];

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedPostOffice;

  bool _loadingProvinces = true;
  bool _loadingDistricts = false;
  bool _loadingPostOffices = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedProvince = widget.initialProvince;
    _selectedDistrict = widget.initialDistrict;
    _selectedPostOffice = widget.initialPostOffice;
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final list = await fetchProvinces(api);
      if (!mounted) return;
      setState(() {
        _provinces = list;
        _loadingProvinces = false;
        if (_selectedProvince != null && !list.any((p) => p.province == _selectedProvince)) {
          _selectedProvince = null;
          _selectedDistrict = null;
          _selectedPostOffice = null;
          _districts = [];
          _postOffices = [];
        } else if (_selectedProvince != null) {
          _loadDistricts();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProvinces = false;
        _error = 'Failed to load provinces. Please try again.';
      });
    }
  }

  Future<void> _loadDistricts() async {
    final province = _selectedProvince;
    if (province == null || province.isEmpty) {
      setState(() {
        _districts = [];
        _postOffices = [];
        _selectedDistrict = null;
        _selectedPostOffice = null;
      });
      return;
    }
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _postOffices = [];
      _selectedDistrict = null;
      _selectedPostOffice = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final list = await fetchDistricts(api, province);
      if (!mounted) return;
      setState(() {
        _districts = list;
        _loadingDistricts = false;
        if (widget.initialDistrict != null && list.any((d) => d.district == widget.initialDistrict)) {
          _selectedDistrict = widget.initialDistrict;
          _loadPostOffices();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDistricts = false;
        _error = 'Failed to load districts.';
      });
    }
  }

  Future<void> _loadPostOffices() async {
    final district = _selectedDistrict;
    if (district == null || district.isEmpty) {
      setState(() {
        _postOffices = [];
        _selectedPostOffice = null;
      });
      return;
    }
    setState(() {
      _loadingPostOffices = true;
      _postOffices = [];
      _selectedPostOffice = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final list = await fetchPostOffices(api, district);
      if (!mounted) return;
      setState(() {
        _postOffices = list;
        _loadingPostOffices = false;
        if (widget.initialPostOffice != null && list.any((p) => p.postOffice == widget.initialPostOffice)) {
          _selectedPostOffice = widget.initialPostOffice;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPostOffices = false;
        _error = 'Failed to load post offices.';
      });
    }
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
        title: const Text('Delivery Address'),
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
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

            // Province
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              decoration: _inputDecoration('Province'),
              hint: Text(_loadingProvinces ? 'Loading...' : 'Select Province'),
              items: _provinces
                  .map((p) => DropdownMenuItem(value: p.province, child: Text(p.province)))
                  .toList(),
              onChanged: _loadingProvinces
                  ? null
                  : (v) {
                      setState(() {
                        _selectedProvince = v;
                        _selectedDistrict = null;
                        _selectedPostOffice = null;
                        _districts = [];
                        _postOffices = [];
                      });
                      if (v != null && v.isNotEmpty) _loadDistricts();
                    },
            ),
            const SizedBox(height: 16),

            // District
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: _inputDecoration('District'),
              hint: Text(
                _loadingDistricts
                    ? 'Loading...'
                    : _selectedProvince == null
                        ? 'Select Province first'
                        : 'Select District',
              ),
              items: _districts
                  .map((d) => DropdownMenuItem(value: d.district, child: Text(d.district)))
                  .toList(),
              onChanged: (_loadingDistricts || _selectedProvince == null)
                  ? null
                  : (v) {
                      setState(() {
                        _selectedDistrict = v;
                        _selectedPostOffice = null;
                        _postOffices = [];
                      });
                      if (v != null && v.isNotEmpty) _loadPostOffices();
                    },
            ),
            const SizedBox(height: 16),

            // Post Office
            DropdownButtonFormField<String>(
              value: _selectedPostOffice,
              decoration: _inputDecoration('Post Office'),
              hint: Text(
                _loadingPostOffices
                    ? 'Loading...'
                    : _selectedDistrict == null
                        ? 'Select District first'
                        : 'Select Post Office',
              ),
              items: _postOffices
                  .map((p) => DropdownMenuItem(value: p.postOffice, child: Text(p.postOffice)))
                  .toList(),
              onChanged: (_loadingPostOffices || _selectedDistrict == null) ? null : (v) => setState(() => _selectedPostOffice = v),
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
                    : const Text('Confirm & Continue'),
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
