import '../core/config/api_config.dart';

enum UserRole { buyer, vendor, admin }

UserRole roleFromString(String? value) {
  // Normalize string to lowercase and trim any whitespace
  final cleanValue = value?.trim().toLowerCase();

  switch (cleanValue) {
    case 'vendor':
      return UserRole.vendor;
    case 'admin':
      return UserRole.admin;
    case 'buyer':
    default:
      return UserRole.buyer;
  }
}

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final UserRole role;
  final bool isVerified;
  final String? businessName;
  final String? businessAddress;
  final String? businessId; // CAC number
  final double rating;
  final DateTime? memberSince;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.isVerified = false,
    this.businessName,
    this.businessAddress,
    this.businessId,
    this.rating = 0,
    this.memberSince,
    this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: roleFromString(json['role']?.toString()),
      isVerified: json['is_verified'] ?? json['verified'] ?? false,
      businessName: json['business_name'],
      businessAddress: json['business_address'],
      businessId: json['cac_number'],
      rating: (json['rating'] ?? 0).toDouble(),
      memberSince: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      photoUrl: json['photo_url'] ?? json['avatar_url'] ?? json['photo'],
    );
  }

  bool get isVendor => role == UserRole.vendor;
  bool get isAdmin => role == UserRole.admin;

  /// The backend sometimes returns a relative storage path
  /// (e.g. "storage/avatars/xxx.jpg") instead of a full URL.
  /// This resolves it against the API's origin (scheme + host only —
  /// uploaded files are served from the web root, not under /api/v1)
  /// so NetworkImage always gets a valid absolute URL.
  String? get avatarDisplayUrl {
    final raw = photoUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final origin =
        Uri.parse(ApiConfig.baseUrl).origin; // https://sbraisolutions.com
    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$origin/$path';
  }

  /// Returns a copy of this user with the given fields replaced.
  /// Useful after a profile update (e.g. new photo) so you don't
  /// have to re-parse a full JSON response just to swap one field.
  AppUser copyWith({
    String? fullName,
    String? phone,
    String? businessName,
    String? businessAddress,
    bool? isVerified,
    String? photoUrl,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      isVerified: isVerified ?? this.isVerified,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessId: businessId,
      rating: rating,
      memberSince: memberSince,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
