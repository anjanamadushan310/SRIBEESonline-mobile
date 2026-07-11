/// SRIBEESonline - Cascading Province → District → Post Office selector.
///
/// One implementation shared by the guest form and the saved-address form, so
/// the two can't drift apart. Every option is fetched live from the backend's
/// Post Office directory via [provincesProvider] / [districtsProvider] /
/// [postOfficesProvider] — there is no hardcoded coverage list anywhere.
///
/// The widget is stateless about *selection*: the parent owns the three values
/// and is told when one changes. It only owns *fetching* and the loading/error
/// presentation for each level.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/location_provider.dart';

/// Display strings, so callers can localize (the guest form is en/si/ta).
class LocationCascadeLabels {
  final String province;
  final String district;
  final String postOffice;
  final String selectProvince;
  final String selectDistrict;
  final String selectPostOffice;

  const LocationCascadeLabels({
    this.province = 'Province',
    this.district = 'District',
    this.postOffice = 'Post Office',
    this.selectProvince = 'Select Province',
    this.selectDistrict = 'Select District',
    this.selectPostOffice = 'Select Post Office',
  });
}

class LocationCascadeSelector extends ConsumerWidget {
  final String? selectedProvince;
  final String? selectedDistrict;
  final String? selectedPostOffice;

  /// Fired with the new province. The parent must clear district + post office.
  final ValueChanged<String?> onProvinceChanged;

  /// Fired with the new district. The parent must clear post office.
  final ValueChanged<String?> onDistrictChanged;

  /// Fired with the new post office. Carries the serving branch when the
  /// backend supplied one, so the caller can show `Delivered by [branch]`.
  final void Function(String? postOffice, String? branchName) onPostOfficeChanged;

  final InputDecoration Function(String label) decorationBuilder;
  final LocationCascadeLabels labels;

  /// Disables every dropdown (e.g. while the form is submitting).
  final bool enabled;

  const LocationCascadeSelector({
    super.key,
    required this.selectedProvince,
    required this.selectedDistrict,
    required this.selectedPostOffice,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onPostOfficeChanged,
    required this.decorationBuilder,
    this.labels = const LocationCascadeLabels(),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provinces = ref.watch(provincesProvider);
    final province = selectedProvince?.trim() ?? '';
    final district = selectedDistrict?.trim() ?? '';

    // Only fetch the next level once the previous one is chosen; the providers
    // short-circuit on an empty key, so these stay cheap.
    final districts = ref.watch(districtsProvider(province));
    final postOffices = ref.watch(postOfficesProvider(district));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AsyncDropdown<String>(
          async: provinces.whenData((list) => list.map((p) => p.province).toList()),
          value: selectedProvince,
          label: labels.province,
          hint: labels.selectProvince,
          emptyHint: 'No delivery areas available yet',
          enabled: enabled,
          decorationBuilder: decorationBuilder,
          onRetry: () => ref.invalidate(provincesProvider),
          onChanged: onProvinceChanged,
        ),
        const SizedBox(height: 16),
        _AsyncDropdown<String>(
          async: districts.whenData((list) => list.map((d) => d.district).toList()),
          value: selectedDistrict,
          label: labels.district,
          hint: province.isEmpty ? '${labels.selectProvince} first' : labels.selectDistrict,
          emptyHint: 'No districts covered in this province',
          // A district can't be picked before its province.
          enabled: enabled && province.isNotEmpty,
          decorationBuilder: decorationBuilder,
          onRetry: () => ref.invalidate(districtsProvider(province)),
          onChanged: onDistrictChanged,
        ),
        const SizedBox(height: 16),
        _AsyncDropdown<String>(
          async: postOffices.whenData((list) => list.map((p) => p.postOffice).toList()),
          value: selectedPostOffice,
          label: labels.postOffice,
          hint: district.isEmpty ? '${labels.selectDistrict} first' : labels.selectPostOffice,
          emptyHint: 'No post offices covered in this district',
          enabled: enabled && district.isNotEmpty,
          decorationBuilder: decorationBuilder,
          onRetry: () => ref.invalidate(postOfficesProvider(district)),
          onChanged: (po) {
            // Hand back the serving branch alongside the post office.
            final loaded = postOffices.asData?.value ?? const [];
            final matches = loaded.where((p) => p.postOffice == po);
            onPostOfficeChanged(
              po,
              matches.isEmpty ? null : matches.first.branchName,
            );
          },
        ),
      ],
    );
  }
}

/// A dropdown driven by an [AsyncValue] list: spinner while loading, an inline
/// retry on failure, and the options once they arrive.
class _AsyncDropdown<T> extends StatelessWidget {
  final AsyncValue<List<T>> async;
  final T? value;
  final String label;
  final String hint;
  final String emptyHint;
  final bool enabled;
  final InputDecoration Function(String label) decorationBuilder;
  final VoidCallback onRetry;
  final ValueChanged<T?> onChanged;

  const _AsyncDropdown({
    required this.async,
    required this.value,
    required this.label,
    required this.hint,
    required this.emptyHint,
    required this.enabled,
    required this.decorationBuilder,
    required this.onRetry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => DropdownButtonFormField<T>(
        value: null,
        decoration: decorationBuilder(label),
        hint: const Text('Loading…'),
        items: const [],
        onChanged: null,
      ),
      error: (_, __) => InputDecorator(
        decoration: decorationBuilder(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Could not load $label.',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
      data: (items) {
        // DropdownButtonFormField asserts that `value` matches exactly one item.
        // A stale selection — an address saved when an area was still covered,
        // then un-mapped by an admin — would otherwise crash the form, so fall
        // back to no selection and let the user re-pick.
        final safeValue = (value != null && items.contains(value)) ? value : null;

        return DropdownButtonFormField<T>(
          value: safeValue,
          decoration: decorationBuilder(label),
          hint: Text(items.isEmpty ? emptyHint : hint),
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text('$item', overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (enabled && items.isNotEmpty) ? onChanged : null,
        );
      },
    );
  }
}
