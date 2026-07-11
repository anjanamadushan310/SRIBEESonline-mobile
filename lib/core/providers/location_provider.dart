/// SRIBEESonline - Location Providers
///
/// Riverpod providers backing the cascading Province → District → Post Office
/// address dropdowns. These are the single source of truth for delivery areas:
/// the lists come from the backend's Post Office directory, never from
/// hardcoded constants, so newly-covered areas appear in the app the moment an
/// admin maps them — no app release required.
///
/// Endpoints (public — they work for guests and signed-in users alike):
///   GET /locations/provinces
///   GET /locations/districts?province=
///   GET /locations/post-offices?district=
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/locations_api.dart';

/// All provinces that have at least one active branch mapping.
///
/// Cached for the session rather than `autoDispose`d: the directory changes
/// rarely, and the address form is re-entered often (add, then edit, then fix a
/// typo). Re-fetching the same short list on every visit would just add a
/// spinner to a screen the user is trying to get through. Call
/// `ref.invalidate(provincesProvider)` to force a refresh.
final provincesProvider = FutureProvider<List<ProvinceItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return fetchProvinces(api);
});

/// Districts within [province] — the second step of the cascade.
///
/// Keyed by province name, so switching province yields that province's own
/// districts and each result is cached independently. An empty/blank province
/// short-circuits to an empty list rather than firing a doomed request.
final districtsProvider =
    FutureProvider.family<List<DistrictItem>, String>((ref, province) async {
  if (province.trim().isEmpty) return const [];
  final api = ref.watch(apiClientProvider);
  return fetchDistricts(api, province);
});

/// Post offices within [district] — the final step, and the one that matters:
/// the chosen post office resolves to the serving branch.
final postOfficesProvider =
    FutureProvider.family<List<PostOfficeItem>, String>((ref, district) async {
  if (district.trim().isEmpty) return const [];
  final api = ref.watch(apiClientProvider);
  return fetchPostOffices(api, district);
});

/// Drop every cached location list.
///
/// Use after an admin-side coverage change, or on pull-to-refresh, when the
/// user needs to see areas that were added since the app started.
void invalidateLocations(WidgetRef ref) {
  ref.invalidate(provincesProvider);
  ref.invalidate(districtsProvider);
  ref.invalidate(postOfficesProvider);
}
