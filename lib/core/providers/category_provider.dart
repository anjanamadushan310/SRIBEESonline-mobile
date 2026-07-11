/// SRIBEESonline - Category Providers
///
/// The storefront category list, straight from the backend. There is no local
/// fallback list: a hardcoded set of categories would quietly disagree with the
/// catalog the admins actually curate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/categories_api.dart';

/// Top-level categories — the home screen's "Shop by Category" tiles.
///
/// Cached for the session rather than `autoDispose`d: the category list is small
/// and changes rarely, and the home screen is returned to constantly. Call
/// `ref.invalidate(topLevelCategoriesProvider)` on pull-to-refresh.
///
/// Categories are global, not branch-scoped — the *products* inside them are
/// what a branch filters — so this does not need invalidating when the branch
/// changes.
final topLevelCategoriesProvider =
    FutureProvider<List<CategoryItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return fetchCategories(api, topLevelOnly: true);
});

/// Sub-categories of [parentId], for drilling into a category.
final subcategoriesProvider =
    FutureProvider.family<List<CategoryItem>, String>((ref, parentId) async {
  if (parentId.trim().isEmpty) return const [];
  final api = ref.watch(apiClientProvider);
  final all = await fetchCategories(api);
  return all.where((c) => c.parentCategoryId == parentId).toList();
});
