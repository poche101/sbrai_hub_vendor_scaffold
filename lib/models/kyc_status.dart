/// Per-field verification status. Email/phone OTP and NIN/BVN lookups are
/// typically instant, but document-based checks (driver's license,
/// passport, business/CAC) go through the admin panel's KYC queue
/// (routes/admin.php: GET kyc-requests, POST kyc/{id}/approve|reject)
/// before they become "verified" — so every field needs to represent
/// more than just true/false.
enum KycFieldStatus { notStarted, pending, verified, rejected }

KycFieldStatus _fieldStatusFromJson(dynamic value) {
  // Accept either a status string ('pending'/'verified'/'rejected') or a
  // legacy boolean, so this keeps working regardless of which shape the
  // backend field ends up using.
  if (value is bool) return value ? KycFieldStatus.verified : KycFieldStatus.notStarted;
  switch (value?.toString()) {
    case 'verified':
    case 'approved':
      return KycFieldStatus.verified;
    case 'pending':
    case 'under_review':
      return KycFieldStatus.pending;
    case 'rejected':
    case 'declined':
      return KycFieldStatus.rejected;
    default:
      return KycFieldStatus.notStarted;
  }
}

class KycStatus {
  final KycFieldStatus email;
  final KycFieldStatus phone;
  final KycFieldStatus identity;
  final KycFieldStatus business;

  /// Optional reason strings surfaced by the admin panel when a field is
  /// rejected (kyc.reject likely takes/returns a reason).
  final String? identityRejectionReason;
  final String? businessRejectionReason;

  KycStatus({
    this.email = KycFieldStatus.notStarted,
    this.phone = KycFieldStatus.notStarted,
    this.identity = KycFieldStatus.notStarted,
    this.business = KycFieldStatus.notStarted,
    this.identityRejectionReason,
    this.businessRejectionReason,
  });

  factory KycStatus.fromJson(Map<String, dynamic> json) {
    return KycStatus(
      email: _fieldStatusFromJson(json['email_status'] ?? json['email_verified']),
      phone: _fieldStatusFromJson(json['phone_status'] ?? json['phone_verified']),
      identity: _fieldStatusFromJson(json['identity_status'] ?? json['identity_verified']),
      // MonoKycController::status() has no separate business_status field —
      // the CAC/business-verified badge is the user's overall `is_verified`
      // flag.
      business: _fieldStatusFromJson(json['business_status'] ?? json['business_verified'] ?? json['is_verified']),
      // Backend only exposes one overall `rejection_reason`, not per-field
      // reasons, so surface it for whichever step is currently rejected.
      identityRejectionReason: json['identity_rejection_reason'] ?? json['rejection_reason'],
      businessRejectionReason: json['business_rejection_reason'] ?? json['rejection_reason'],
    );
  }

  // Backward-compatible boolean convenience getters used across the UI.
  bool get emailVerified => email == KycFieldStatus.verified;
  bool get phoneVerified => phone == KycFieldStatus.verified;
  bool get identityVerified => identity == KycFieldStatus.verified;
  bool get businessVerified => business == KycFieldStatus.verified;

  bool get identityPending => identity == KycFieldStatus.pending;
  bool get businessPending => business == KycFieldStatus.pending;
  bool get identityRejected => identity == KycFieldStatus.rejected;
  bool get businessRejected => business == KycFieldStatus.rejected;

  int get completedSteps =>
      [emailVerified, phoneVerified, identityVerified, businessVerified].where((e) => e).length;

  double get progress => completedSteps / 4;

  /// Minimum bar to post an ad: email + phone + identity fully VERIFIED
  /// (not merely submitted/pending admin review).
  bool get meetsMinimumForSelling => emailVerified && phoneVerified && identityVerified;

  /// Same threshold, role-neutral name used for buyers: a buyer must be
  /// email + phone + NIN verified before they can call or chat a vendor.
  bool get canTransact => emailVerified && phoneVerified && identityVerified;
}
