/// SRIBEESonline - Locations API
///
/// Fetches Province → District → Post Office for cascading address selection.
/// Endpoints: GET /locations/provinces, /locations/districts, /locations/post-offices.
library;

import 'api_client.dart';

/// Single province from GET /locations/provinces.
class ProvinceItem {
  final String province;
  final int districtCount;
  final int postOfficeCount;
  final int branchCount;

  ProvinceItem({
    required this.province,
    required this.districtCount,
    required this.postOfficeCount,
    required this.branchCount,
  });

  factory ProvinceItem.fromJson(Map<String, dynamic> json) {
    return ProvinceItem(
      province: json['province'] as String? ?? '',
      districtCount: (json['districtCount'] ?? json['district_count'] ?? 0) as int,
      postOfficeCount: (json['postOfficeCount'] ?? json['post_office_count'] ?? 0) as int,
      branchCount: (json['branchCount'] ?? json['branch_count'] ?? 0) as int,
    );
  }
}

/// Single district from GET /locations/districts.
class DistrictItem {
  final String district;
  final String province;
  final int postOfficeCount;

  DistrictItem({
    required this.district,
    required this.province,
    required this.postOfficeCount,
  });

  factory DistrictItem.fromJson(Map<String, dynamic> json) {
    return DistrictItem(
      district: json['district'] as String? ?? '',
      province: json['province'] as String? ?? '',
      postOfficeCount: (json['postOfficeCount'] ?? json['post_office_count'] ?? 0) as int,
    );
  }
}

/// Single post office from GET /locations/post-offices.
class PostOfficeItem {
  final String postOffice;
  final String district;
  final String province;

  PostOfficeItem({
    required this.postOffice,
    required this.district,
    required this.province,
  });

  factory PostOfficeItem.fromJson(Map<String, dynamic> json) {
    return PostOfficeItem(
      postOffice: json['postOffice'] as String? ?? json['post_office'] as String? ?? '',
      district: json['district'] as String? ?? '',
      province: json['province'] as String? ?? '',
    );
  }
}

/// Fetches locations for cascading dropdowns.
Future<List<ProvinceItem>> fetchProvinces(ApiClient api) async {
  final response = await api.get<Map<String, dynamic>>('/locations/provinces');
  final data = response['data'];
  final list = data is List ? data : <dynamic>[];
  return list
      .map((e) => ProvinceItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Fetches districts for a province.
Future<List<DistrictItem>> fetchDistricts(ApiClient api, String province) async {
  if (province.isEmpty) return [];
  final response = await api.get<Map<String, dynamic>>(
    '/locations/districts',
    queryParameters: {'province': province},
  );
  final data = response['data'];
  final list = data is List ? data : <dynamic>[];
  return list
      .map((e) => DistrictItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Fetches post offices for a district.
Future<List<PostOfficeItem>> fetchPostOffices(ApiClient api, String district) async {
  if (district.isEmpty) return [];
  final response = await api.get<Map<String, dynamic>>(
    '/locations/post-offices',
    queryParameters: {'district': district},
  );
  final data = response['data'];
  final list = data is List ? data : <dynamic>[];
  return list
      .map((e) => PostOfficeItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}
