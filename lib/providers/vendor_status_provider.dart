import 'package:flutter/foundation.dart';
import '../models/kyc_status.dart';
import '../models/subscription.dart';
import '../services/kyc_service.dart';
import '../services/subscription_service.dart';

/// Tracks the signed-in user's KYC status (used by BOTH buyers and
/// vendors — buyers need it to unlock contacting sellers, vendors need
/// it plus an active subscription to unlock posting ads) and, for
/// vendors, subscription status.
///
/// Single source of truth for "can this vendor post an ad right now?"
/// and "can this buyer contact a seller right now?". A vendor must have
/// completed the minimum KYC checks (email, phone, identity) AND have an
/// active subscription (₦25,000 / 10 Espees) before the Post Ad flow
/// lets them through. A buyer only needs the KYC checks (email, phone,
/// NIN) to contact a vendor — see [ContactGate].
class VendorStatusProvider extends ChangeNotifier {
  final _kycService = KycService();
  final _subscriptionService = SubscriptionService();

  KycStatus kyc = KycStatus();
  SubscriptionStatus subscription = SubscriptionStatus();
  bool isLoading = false;
  String? error;

  bool get canPostAd => kyc.meetsMinimumForSelling && subscription.isActive;

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _kycService.getStatus(),
        _subscriptionService.getStatus(),
      ]);
      kyc = results[0] as KycStatus;
      subscription = results[1] as SubscriptionStatus;
    } catch (e) {
      error = 'Could not load your vendor status. Pull to refresh to try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateKyc(KycStatus status) {
    kyc = status;
    notifyListeners();
  }

  void updateSubscription(SubscriptionStatus status) {
    subscription = status;
    notifyListeners();
  }
}
