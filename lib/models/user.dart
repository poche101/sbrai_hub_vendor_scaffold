enum UserRole { buyer, vendor, admin }

UserRole roleFromString(String? value) {
  switch (value) {
    case 'vendor':
      return UserRole.vendor;
    case 'admin':
      return UserRole.admin;
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
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: roleFromString(json['role']),
      isVerified: json['is_verified'] ?? json['verified'] ?? false,
      businessName: json['business_name'],
      businessAddress: json['business_address'],
      businessId: json['cac_number'],
      rating: (json['rating'] ?? 0).toDouble(),
      memberSince: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  bool get isVendor => role == UserRole.vendor;
}
