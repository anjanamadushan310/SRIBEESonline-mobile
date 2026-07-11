/// SRIBEESonline - Categories API
///
/// Fetches the storefront category list. Endpoint: GET /categories.
///
/// The catalog is two levels deep (Category → Sub-category). The home screen
/// shows one image tile per TOP-LEVEL category, so it asks the server for those
/// directly (`top_level_only=true`) rather than pulling the whole tree and
/// discarding most of it.
library;

import 'api_client.dart';

/// A storefront category.
class CategoryItem {
  final String id;
  final String name;
  final String slug;

  /// Tile image. Only top-level categories carry one — the API rejects an image
  /// on a sub-category — so this is null for sub-categories, and may also be
  /// null for a top-level category an admin has not given an image yet.
  final String? imageUrl;

  final String? parentCategoryId;
  final int productCount;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.parentCategoryId,
    this.productCount = 0,
  });

  bool get isTopLevel => parentCategoryId == null;

  /// True when there is a usable image to render.
  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'] as String?;
    final rawParent = json['parent_category_id'];
    return CategoryItem(
      id: (json['category_id'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: (rawImage != null && rawImage.trim().isNotEmpty) ? rawImage : null,
      parentCategoryId:
          (rawParent == null || rawParent.toString().isEmpty) ? null : rawParent.toString(),
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Fetch categories. Pass [topLevelOnly] for the home-screen tiles.
Future<List<CategoryItem>> fetchCategories(
  ApiClient api, {
  bool topLevelOnly = false,
}) async {
  final response = await api.get<Map<String, dynamic>>(
    // Base URL already includes /api/v1 — do not repeat the prefix here.
    '/categories',
    queryParameters: topLevelOnly ? {'top_level_only': true} : null,
  );

  final data = (response['data'] as Map?) ?? const {};
  final list = (data['categories'] as List?) ?? const [];
  return list
      .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}
