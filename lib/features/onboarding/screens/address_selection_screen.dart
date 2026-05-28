/// SRIBEESonline - Address Selection Screen
///
/// For authenticated users: list saved addresses with radio selection,
/// edit icon → AddressFormScreen, "Add New Address" → AddressFormScreen.
/// For guests: show Province → District → Post Office form inline.
/// On resolve (address or location), branch is stored and user goes to Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/branch_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../home/screens/home_screen.dart';
import 'address_form_screen.dart';

// Maroon / Green grocery theme
const _maroon = Color(0xFF6B2D5C);
const _green = Color(0xFF2D5C4A);

// Static data for guest address form (Western Province → Kalutara → 3 POs)
const _westernProvince = 'Western Province';
const _kalutara = 'Kalutara';
const _postOfficeOptions = ['Welipenna', 'Mathugama', 'Meegahathanna'];

// Localized labels for guest form (en, si, ta)
const _guestFormCopy = {
  'en': (
    province: 'Province',
    district: 'District',
    postOffice: 'Post Office',
    selectProvince: 'Select Province',
    selectDistrict: 'Select District',
    selectPostOffice: 'Select Post Office',
    addressLine1: 'Address Line 1 (Street/House No)',
    addressLine2: 'Address Line 2 (Locality/Village)',
    addressLine1Hint: 'Street name and house number',
    addressLine2Hint: 'Locality or village name',
    confirm: 'Confirm & Continue',
    comingSoon: 'Coming Soon',
    enterDeliveryArea: 'Enter your delivery area',
    provinceDistrictPo: 'Province → District → Post Office',
    fillAllFields: 'Please fill all fields.',
  ),
  'si': (
    province: 'පළාත',
    district: 'දිස්ත්‍රික්කය',
    postOffice: 'තැපැල් කාර්යාලය',
    selectProvince: 'පළාත තෝරන්න',
    selectDistrict: 'දිස්ත්‍රික්කය තෝරන්න',
    selectPostOffice: 'තැපැල් කාර්යාලය තෝරන්න',
    addressLine1: 'ලිපින පේළිය 1 (වීදිය/ගෙයි අංකය)',
    addressLine2: 'ලිපින පේළිය 2 (ප්‍රදේශය/ගම)',
    addressLine1Hint: 'වීදි නම සහ ගෙයි අංකය',
    addressLine2Hint: 'ප්‍රදේශය හෝ ගම් නාමය',
    confirm: 'තහවුරු කර ඉදිරියට යන්න',
    comingSoon: 'ඉක්මනින්',
    enterDeliveryArea: 'ඔබේ බෙදාහැරීම් ප්‍රදේශය ඇතුළත් කරන්න',
    provinceDistrictPo: 'පළාත → දිස්ත්‍රික්කය → තැපැල් කාර්යාලය',
    fillAllFields: 'කරුණාකර සියලු ක්ෂේත්‍ර පුරවන්න.',
  ),
  'ta': (
    province: 'மாகாணம்',
    district: 'மாவட்டம்',
    postOffice: 'தபால் நிலையம்',
    selectProvince: 'மாகாணத்தைத் தேர்ந்தெடுக்கவும்',
    selectDistrict: 'மாவட்டத்தைத் தேர்ந்தெடுக்கவும்',
    selectPostOffice: 'தபால் நிலையத்தைத் தேர்ந்தெடுக்கவும்',
    addressLine1: 'முகவரி வரி 1 (தெரு/வீடு எண்)',
    addressLine2: 'முகவரி வரி 2 (பகுதி/கிராமம்)',
    addressLine1Hint: 'தெரு பெயர் மற்றும் வீடு எண்',
    addressLine2Hint: 'பகுதி அல்லது கிராமப் பெயர்',
    confirm: 'உறுதிசெய்து தொடரவும்',
    comingSoon: 'விரைவில்',
    enterDeliveryArea: 'உங்கள் விநியோக பகுதியை உள்ளிடவும்',
    provinceDistrictPo: 'மாகாணம் → மாவட்டம் → தபால் நிலையம்',
    fillAllFields: 'அனைத்து புலங்களையும் பூர்த்தி செய்யவும்.',
  ),
};

class AddressSelectionScreen extends ConsumerStatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  ConsumerState<AddressSelectionScreen> createState() =>
      _AddressSelectionScreenState();
}

class _AddressSelectionScreenState
    extends ConsumerState<AddressSelectionScreen> {
  // Authenticated list state
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  String? _error;
  String? _selectedAddressId; // radio selection
  String? _resolvingId;

  // Guest form state (static data: Western Province → Kalutara → 3 POs)
  String? _guestProvince;
  String? _guestDistrict;
  String? _guestPostOffice;
  bool _guestSubmitting = false;
  final _guestAddressLine1Controller = TextEditingController();
  final _guestAddressLine2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _branchByAuth());
  }

  @override
  void dispose() {
    _guestAddressLine1Controller.dispose();
    _guestAddressLine2Controller.dispose();
    super.dispose();
  }

  void _branchByAuth() {
    final isAuth = ref.read(isAuthenticatedProvider);
    if (isAuth) {
      _fetchAddresses();
    } else {
      _initGuestFormData();
    }
  }

  /// Initialize guest form with default Province/District and static Post Office list.
  void _initGuestFormData() {
    setState(() {
      _guestProvince = _westernProvince;
      _guestDistrict = _kalutara;
      _guestPostOffice = null;
    });
  }

  String _t(String? code, String key) {
    final c = _guestFormCopy[code ?? 'en'] ?? _guestFormCopy['en']!;
    switch (key) {
      case 'province': return c.province;
      case 'district': return c.district;
      case 'selectProvince': return c.selectProvince;
      case 'selectDistrict': return c.selectDistrict;
      case 'postOffice': return c.postOffice;
      case 'selectPostOffice': return c.selectPostOffice;
      case 'addressLine1': return c.addressLine1;
      case 'addressLine2': return c.addressLine2;
      case 'addressLine1Hint': return c.addressLine1Hint;
      case 'addressLine2Hint': return c.addressLine2Hint;
      case 'confirm': return c.confirm;
      case 'comingSoon': return c.comingSoon;
      case 'enterDeliveryArea': return c.enterDeliveryArea;
      case 'provinceDistrictPo': return c.provinceDistrictPo;
      case 'fillAllFields': return c.fillAllFields;
      default: return '';
    }
  }

  bool get _canSubmitGuestForm {
    final p = _guestProvince?.trim();
    final d = _guestDistrict?.trim();
    final po = _guestPostOffice?.trim();
    final a1 = _guestAddressLine1Controller.text.trim();
    final a2 = _guestAddressLine2Controller.text.trim();
    return (p != null && p.isNotEmpty &&
        d != null && d.isNotEmpty &&
        po != null && po.isNotEmpty &&
        a1.isNotEmpty && a2.isNotEmpty);
  }

  InputDecoration _guestInputDecoration(String label, [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _maroon, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ========================================================================
  // Authenticated: fetch addresses
  // ========================================================================

  Future<void> _fetchAddresses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get<Map<String, dynamic>>('/user/addresses');

      final data = response['data'];
      final List<dynamic> raw =
          data is List ? data : (data is Map ? (data['addresses'] ?? []) : []);

      setState(() {
        _addresses =
            raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
        if (_addresses.isNotEmpty && _selectedAddressId == null) {
          final firstId = (_addresses.first['address_id'] ?? _addresses.first['id'] ?? '').toString();
          if (firstId.isNotEmpty) _selectedAddressId = firstId;
        }
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load addresses. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _onConfirmAddress() async {
    final id = _selectedAddressId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an address.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _resolvingId = id);

    try {
      final branchNotifier = ref.read(branchProvider.notifier);
      await branchNotifier.resolveFromAddress(id);
      final branchName = ref.read(branchProvider)?.branchName;
      if (!mounted) return;
      pushAndClearFade(context, HomeScreen(branchName: branchName));
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      setState(() => _resolvingId = null);
    } catch (e) {
      if (!mounted) return;
      _showError('Could not resolve branch. Please try another address.');
      setState(() => _resolvingId = null);
    }
  }

  void _openEditAddress(Map<String, dynamic> address) {
    final province = address['province'] ?? address['Province'] ?? '';
    final district = address['district'] ?? address['District'] ?? '';
    final postOffice = address['post_office'] ?? address['postOffice'] ?? address['post office'] ?? '';
    pushFade(
      context,
      AddressFormScreen(
        initialProvince: province.isEmpty ? null : province,
        initialDistrict: district.isEmpty ? null : district,
        initialPostOffice: postOffice.isEmpty ? null : postOffice,
      ),
    ).then((_) {
      if (mounted) _fetchAddresses();
    });
  }

  void _openAddNewAddress() {
    pushFade(context, const AddressFormScreen()).then((_) {
      if (mounted) _fetchAddresses();
    });
  }

  // ========================================================================
  // Guest: cascading dropdowns
  // ========================================================================

  Future<void> _submitGuestForm() async {
    final langCode = ref.read(languageProvider)?.languageCode ?? 'en';

    if (!_canSubmitGuestForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(langCode, 'fillAllFields')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final province = _guestProvince!.trim();
    final district = _guestDistrict!.trim();
    final postOffice = _guestPostOffice!.trim();
    setState(() => _guestSubmitting = true);

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
      setState(() => _guestSubmitting = false);
    } catch (e) {
      if (!mounted) return;
      _showError('Could not resolve branch. Please try another area.');
      setState(() => _guestSubmitting = false);
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

  // ========================================================================
  // Build
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(isAuthenticatedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Delivery Address'),
        automaticallyImplyLeading: false,
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
      ),
      body: isAuth ? _buildAuthenticatedBody(theme) : _buildGuestBody(theme),
    );
  }

  Widget _buildAuthenticatedBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError(theme);
    }
    if (_addresses.isEmpty) {
      return _buildEmpty(theme);
    }
    return _buildAddressList(theme);
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAddresses,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _maroon,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No saved addresses.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a delivery address below to continue.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAddNewAddress,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add New Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: _addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final addr = _addresses[index];
              final id = (addr['address_id'] ?? addr['id'] ?? '').toString();
              final isSelected = _selectedAddressId == id;
              final isResolving = _resolvingId == id;

              final label = addr['label'] ?? addr['address_label'] ?? 'Address';
              final line1 = addr['address_line_1'] ?? addr['address_line1'] ?? addr['street'] ?? '';
              final line2 = addr['address_line_2'] ?? addr['address_line2'] ?? '';
              final city = addr['city'] ?? addr['post_office'] ?? addr['postOffice'] ?? '';
              final district = addr['district'] ?? '';

              final subtitle = [line1, line2, city, district]
                  .where((s) => s.toString().isNotEmpty)
                  .join(', ');

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isResolving ? null : () => setState(() => _selectedAddressId = id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? _green : _maroon.withOpacity(0.2),
                        width: isSelected ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: id,
                          groupValue: _selectedAddressId,
                          onChanged: isResolving ? null : (v) => setState(() => _selectedAddressId = v),
                          activeColor: _green,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label.toString(),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: _maroon, size: 22),
                          onPressed: isResolving ? null : () => _openEditAddress(addr),
                          tooltip: 'Edit',
                        ),
                        if (isResolving)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _openAddNewAddress,
                icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                label: const Text('Add New Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _maroon,
                  side: const BorderSide(color: _maroon),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _resolvingId != null ? null : _onConfirmAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _resolvingId != null
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm & Continue'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestBody(ThemeData theme) {
    final langCode = ref.watch(languageProvider)?.languageCode ?? 'en';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        Text(
          _t(langCode, 'enterDeliveryArea'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: _maroon,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _t(langCode, 'provinceDistrictPo'),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
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
                Expanded(
                  child: Text(_error!, style: TextStyle(color: Colors.red[800])),
                ),
              ],
            ),
          ),
        ],
        // Province: default Western Province only (others "Coming Soon" — not selectable)
        DropdownButtonFormField<String>(
          value: _guestProvince,
          decoration: _guestInputDecoration(_t(langCode, 'province')),
          hint: Text(_t(langCode, 'selectProvince')),
          items: [
            DropdownMenuItem(value: _westernProvince, child: Text(_westernProvince)),
          ],
          onChanged: (v) => setState(() => _guestProvince = v),
        ),
        const SizedBox(height: 16),
        // District: default Kalutara
        DropdownButtonFormField<String>(
          value: _guestDistrict,
          decoration: _guestInputDecoration(_t(langCode, 'district')),
          hint: Text(_t(langCode, 'selectDistrict')),
          items: [
            DropdownMenuItem(value: _kalutara, child: Text(_kalutara)),
          ],
          onChanged: (v) => setState(() => _guestDistrict = v),
        ),
        const SizedBox(height: 16),
        // Post Office: Welipenna, Mathugama, Meegahathanna
        DropdownButtonFormField<String>(
          value: _guestPostOffice,
          decoration: _guestInputDecoration(_t(langCode, 'postOffice')),
          hint: Text(_t(langCode, 'selectPostOffice')),
          items: _postOfficeOptions
              .map((po) => DropdownMenuItem(value: po, child: Text(po)))
              .toList(),
          onChanged: (v) => setState(() => _guestPostOffice = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _guestAddressLine1Controller,
          decoration: _guestInputDecoration(
            _t(langCode, 'addressLine1'),
            _t(langCode, 'addressLine1Hint'),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _guestAddressLine2Controller,
          decoration: _guestInputDecoration(
            _t(langCode, 'addressLine2'),
            _t(langCode, 'addressLine2Hint'),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_guestSubmitting || !_canSubmitGuestForm) ? null : _submitGuestForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _guestSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_t(langCode, 'confirm')),
          ),
        ),
      ],
    );
  }
}
