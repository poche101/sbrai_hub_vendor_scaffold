import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/product.dart';
import 'subscription_service.dart';

class DashboardStats {
  final int activeListings;
  final int totalViews;
  final int messages;
  final double totalSales;
  final double adVoucherBalance;
  final List<DashboardActivity> recentActivity;

  DashboardStats({
    this.activeListings = 0,
    this.totalViews = 0,
    this.messages = 0,
    this.totalSales = 0,
    this.adVoucherBalance = 0,
    this.recentActivity = const [],
  });

  /// VendorController::dashboard() returns `{success, stats: {...},
  /// activities: [...]}` — not a `data` wrapper — and its stats field
  /// names differ from the UI's (`total_chats`/`total_revenue`, not
  /// `messages`/`total_sales`). It also has no voucher-balance field at
  /// all (that only lives behind SubscriptionController::voucherBalance),
  /// so [voucherBalance] is merged in separately by [VendorService.getDashboard].
  factory DashboardStats.fromJson(Map<String, dynamic> json, {double voucherBalance = 0}) {
    final stats = (json['stats'] ?? json['data'] ?? json) as Map;
    final activities = (json['activities'] ?? json['recent_activity'] ?? []) as List;
    return DashboardStats(
      activeListings: stats['active_listings'] ?? 0,
      totalViews: stats['total_views'] ?? 0,
      messages: stats['total_chats'] ?? stats['messages'] ?? 0,
      totalSales: (stats['total_revenue'] ?? stats['total_sales'] ?? 0).toDouble(),
      adVoucherBalance: voucherBalance,
      recentActivity: activities.map((e) => DashboardActivity.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class DashboardActivity {
  final String message;
  final DateTime at;
  DashboardActivity({required this.message, required this.at});

  factory DashboardActivity.fromJson(Map<String, dynamic> json) => DashboardActivity(
        message: json['message'] ?? '',
        at: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}

class VendorService {
  final _client = ApiClient.instance;

  Future<DashboardStats> getDashboard() async {
    final dashboardRes = _client.get(ApiConfig.vendorDashboard);
    final voucherRes = SubscriptionService().getVoucherBalance();
    final res = await dashboardRes;
    final voucherBalance = await voucherRes;
    return DashboardStats.fromJson(res.data, voucherBalance: voucherBalance);
  }

  Future<List<Product>> getMyListings() async {
    final res = await _client.get(ApiConfig.vendorListings);
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final res = await _client.get(ApiConfig.vendorAnalytics);
    return Map<String, dynamic>.from(res.data['data'] ?? res.data);
  }
}
