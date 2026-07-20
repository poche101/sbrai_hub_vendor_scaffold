import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

class AppSettings {
  final bool notifyNewListings;
  final bool notifyPriceDrops;
  final bool notifyMessages;
  final bool notifyPromotions;
  final bool showOnlineStatus;
  final bool showPhoneNumber;
  final bool allowMessages;
  final String language;
  final String currency;

  AppSettings({
    this.notifyNewListings = true,
    this.notifyPriceDrops = true,
    this.notifyMessages = true,
    this.notifyPromotions = false,
    this.showOnlineStatus = true,
    this.showPhoneNumber = true,
    this.allowMessages = true,
    this.language = 'English',
    this.currency = 'Nigerian Naira (₦)',
  });

  /// AuthController::getSettings()/updateSettings() return the settings
  /// object under a `settings` key, not `data`. And a user who has never
  /// saved settings gets AuthController::defaultSettings()'s *nested*
  /// shape ({notifications: {new_listings, ...}, privacy: {...}}) back —
  /// only once the app itself writes settings (via [toJson], which is
  /// flat) does the stored shape match what's read here directly.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final data = json['settings'] ?? json['data'] ?? json;
    final notifications = (data['notifications'] as Map?) ?? {};
    final privacy = (data['privacy'] as Map?) ?? {};
    return AppSettings(
      notifyNewListings: data['notify_new_listings'] ?? notifications['new_listings'] ?? true,
      notifyPriceDrops: data['notify_price_drops'] ?? notifications['price_drops'] ?? true,
      notifyMessages: data['notify_messages'] ?? notifications['messages'] ?? true,
      notifyPromotions: data['notify_promotions'] ?? notifications['promotions'] ?? false,
      showOnlineStatus: data['show_online_status'] ?? privacy['show_online_status'] ?? true,
      showPhoneNumber: data['show_phone_number'] ?? privacy['show_phone'] ?? true,
      allowMessages: data['allow_messages'] ?? privacy['allow_messages'] ?? true,
      language: data['language'] == 'en' ? 'English' : (data['language'] ?? 'English'),
      currency: data['currency'] == 'NGN' ? 'Nigerian Naira (₦)' : (data['currency'] ?? 'Nigerian Naira (₦)'),
    );
  }

  Map<String, dynamic> toJson() => {
        'notify_new_listings': notifyNewListings,
        'notify_price_drops': notifyPriceDrops,
        'notify_messages': notifyMessages,
        'notify_promotions': notifyPromotions,
        'show_online_status': showOnlineStatus,
        'show_phone_number': showPhoneNumber,
        'allow_messages': allowMessages,
        'language': language,
        'currency': currency,
      };

  AppSettings copyWith({
    bool? notifyNewListings,
    bool? notifyPriceDrops,
    bool? notifyMessages,
    bool? notifyPromotions,
    bool? showOnlineStatus,
    bool? showPhoneNumber,
    bool? allowMessages,
  }) {
    return AppSettings(
      notifyNewListings: notifyNewListings ?? this.notifyNewListings,
      notifyPriceDrops: notifyPriceDrops ?? this.notifyPriceDrops,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyPromotions: notifyPromotions ?? this.notifyPromotions,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      allowMessages: allowMessages ?? this.allowMessages,
      language: language,
      currency: currency,
    );
  }
}

class SettingsService {
  final _client = ApiClient.instance;

  Future<AppSettings> getSettings() async {
    final res = await _client.get(ApiConfig.settings);
    return AppSettings.fromJson(res.data);
  }

  Future<AppSettings> updateSettings(AppSettings settings) async {
    final res = await _client.put(ApiConfig.settings, data: settings.toJson());
    return AppSettings.fromJson(res.data);
  }
}
