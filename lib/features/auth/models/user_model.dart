/// SRIBEESonline - User model
///
/// Matches backend UserResponse / ProfileResponse.user
library;

class User {
  final String userId;
  final String email;
  final String fullName;
  final String? phone;
  final String? profilePictureUrl;
  final bool isVerified;
  final bool twoFactorEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  const User({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.profilePictureUrl,
    this.isVerified = false,
    this.twoFactorEnabled = false,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  /// Development-only: user for mock OTP login (no backend tokens).
  static User get mockUser => const User(
        userId: 'mock-dev-user',
        email: '',
        fullName: 'Dev User',
        phone: null,
        isVerified: true,
      );

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String? ?? json['profile_picture_url'] as String?,
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? json['two_factor_enabled'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      lastLogin: _parseDateTime(json['lastLogin'] ?? json['last_login']),
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'profilePictureUrl': profilePictureUrl,
        'isVerified': isVerified,
        'twoFactorEnabled': twoFactorEnabled,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
      };
}
