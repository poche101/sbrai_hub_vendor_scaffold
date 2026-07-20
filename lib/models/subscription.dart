class SubscriptionStatus {
  final bool isActive;
  final DateTime? expiresAt;
  final String? plan;

  SubscriptionStatus({this.isActive = false, this.expiresAt, this.plan});

  /// SubscriptionController::status() returns:
  ///   { success, subscription: {id, vendor_id, status, start_date,
  ///     end_date, amount_paid, payment_method, transaction_id} | null,
  ///     can_post }
  /// — not a flat is_active/expires_at/plan shape, and not nested under
  /// `data`. `can_post` (KYC-verified AND an active, unexpired
  /// subscription) is what actually gates the Post Ad flow, so it's used
  /// as the source of truth for [isActive] rather than trusting the
  /// subscription's own `status` string in isolation.
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>?;
    return SubscriptionStatus(
      isActive: json['can_post'] ?? (sub != null && sub['status'] == 'active'),
      expiresAt: sub?['end_date'] != null ? DateTime.tryParse(sub!['end_date']) : null,
      plan: sub?['payment_method'],
    );
  }
}
