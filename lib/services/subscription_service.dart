import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/subscription.dart';

class PaymentInit {
  final String? reference;
  final String? checkoutUrl; // hosted checkout page (Paystack storefront or Espees portal)

  PaymentInit({this.reference, this.checkoutUrl});

  factory PaymentInit.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return PaymentInit(
      reference: data['reference']?.toString(),
      checkoutUrl: data['checkout_url'] ?? data['authorization_url'] ?? data['url'],
    );
  }
}

class SubscriptionTransaction {
  final String description;
  final double amount;
  final String currency; // 'NGN' | 'ESP'
  final DateTime date;
  final double balanceAfter;

  SubscriptionTransaction({
    required this.description,
    required this.amount,
    required this.currency,
    required this.date,
    required this.balanceAfter,
  });

  factory SubscriptionTransaction.fromJson(Map<String, dynamic> json) => SubscriptionTransaction(
        description: json['description'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        currency: json['currency'] ?? 'NGN',
        date: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        balanceAfter: (json['balance_after'] ?? 0).toDouble(),
      );
}

class SubscriptionService {
  final _client = ApiClient.instance;

  Future<SubscriptionStatus> getStatus() async {
    final res = await _client.get(ApiConfig.subscriptionStatus);
    return SubscriptionStatus.fromJson(Map<String, dynamic>.from(res.data['data'] ?? res.data));
  }

  Future<List<SubscriptionTransaction>> getTransactions() async {
    final res = await _client.get(ApiConfig.subscriptionTransactions);
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => SubscriptionTransaction.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<double> getVoucherBalance() async {
    final res = await _client.get(ApiConfig.subscriptionVoucherBalance);
    final data = res.data['data'] ?? res.data;
    return (data['balance'] ?? data ?? 0).toDouble();
  }

  /// GET /subscriptions/paystack/checkout — backend creates the Paystack
  /// transaction server-side (holding the secret key) and hands back a
  /// hosted checkout URL for the ₦25,000 fee, opened in a WebView.
  Future<PaymentInit> getPaystackCheckout() async {
    final res = await _client.get(ApiConfig.subscriptionPaystackCheckout);
    return PaymentInit.fromJson(res.data);
  }

  /// POST /subscriptions/paystack/verify — called after the WebView
  /// checkout completes/redirects, with the Paystack reference.
  Future<SubscriptionStatus> verifyPaystack(String reference) async {
    final res = await _client.post(ApiConfig.subscriptionPaystackVerify, data: {
      'reference': reference,
    });
    return SubscriptionStatus.fromJson(Map<String, dynamic>.from(res.data['data'] ?? res.data));
  }

  /// POST /subscriptions/espees/pay — SubscriptionController::payWithEspees()
  /// performs an immediate server-side wallet debit (via EspeesService),
  /// not a hosted-checkout redirect: it requires the vendor's wallet_id +
  /// PIN and returns the resulting `subscription` directly in the same
  /// response, with no separate verify step or WebView involved.
  Future<SubscriptionStatus> payWithEspees({
    required String walletId,
    required String pin,
  }) async {
    final res = await _client.post(ApiConfig.subscriptionEspeesPay, data: {
      'wallet_id': walletId,
      'pin': pin,
      'amount': ApiConfig.subscriptionFeeEspees,
      'description': 'Sbrai Hub Vendor Annual Subscription',
    });
    final data = res.data as Map<String, dynamic>;
    // Reuses SubscriptionStatus's { subscription: {...} } parsing; this
    // endpoint doesn't return `can_post`, so treat a successful debit as
    // active directly.
    final sub = data['subscription'] as Map<String, dynamic>?;
    return SubscriptionStatus(
      isActive: sub != null,
      expiresAt: sub?['end_date'] != null ? DateTime.tryParse(sub!['end_date']) : null,
      plan: sub?['payment_method'],
    );
  }
}
