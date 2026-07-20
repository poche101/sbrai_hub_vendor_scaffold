/// ---------------------------------------------------------------------------
/// API CONFIG — matches routes/api.php exactly (served at
/// https://sbraisolutions.com/api/v1/...). Keep this in sync if the
/// backend route file changes; every service references these constants
/// instead of hardcoding paths.
/// ---------------------------------------------------------------------------
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://sbraisolutions.com/api/v1';

  // ---- Auth (public) ----------------------------------------------------
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password'; // { email, token, password, password_confirmation }
  static String confirmAccount(String token) => '/auth/confirm-account/$token';
  static const String googleAuth = '/auth/google';
  static const String facebookAuth = '/auth/facebook';

  // ---- Auth (authenticated) ---------------------------------------------
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';
  static const String fcmToken = '/auth/fcm-token';
  static const String uploadAvatar = '/auth/avatar';
  static const String resendConfirmation = '/auth/resend-confirmation';
  static const String deleteAccount = '/auth/account';

  // ---- KYC (Mono-powered, step by step) ---------------------------------
  static const String kycStatus = '/kyc/status';
  static const String kycEmailSendOtp = '/kyc/email/send-otp';
  static const String kycEmailVerify = '/kyc/email/verify';
  static const String kycPhoneSendOtp = '/kyc/phone/send-otp';
  static const String kycPhoneVerify = '/kyc/phone/verify';
  static const String kycIdentityNin = '/kyc/identity/nin';
  static const String kycIdentityBvn = '/kyc/identity/bvn';
  static const String kycIdentityDriversLicense = '/kyc/identity/drivers-license';
  static const String kycIdentityPassport = '/kyc/identity/passport';
  static const String kycBusinessCac = '/kyc/business/cac';
  static const String kycIdentityDocuments = '/kyc/identity/documents'; // multipart fallback upload

  // ---- Categories / Listings ---------------------------------------------
  static const String categories = '/categories';
  static const String listings = '/listings';
  static const String listingsTrending = '/listings/trending';
  static const String listingsRecommended = '/listings/recommended';
  static String listing(String id) => '/listings/$id';
  static String listingImages(String id) => '/listings/$id/images';
  static String listingStatus(String id) => '/listings/$id/status';
  static const String search = '/search';

  // ---- Vendor (authenticated vendor/admin only) --------------------------
  static const String vendorListings = '/vendor/listings';
  static const String vendorDashboard = '/vendor/dashboard';
  static const String vendorAnalytics = '/vendor/analytics';

  // ---- Vendor public profile ----------------------------------------------
  static String vendorProfile(String id) => '/vendors/$id';
  static String vendorPublicListings(String id) => '/vendors/$id/listings';
  static String vendorReviews(String id) => '/vendors/$id/reviews';
  static String vendorAddReview(String id) => '/vendors/$id/review';

  // ---- Favorites ------------------------------------------------------------
  static const String favorites = '/favorites';
  static const String favoritesToggle = '/favorites/toggle'; // { listing_id }

  // ---- Chats / Messages ------------------------------------------------------
  static const String chats = '/chats';
  static String chatMessages(String chatId) => '/chats/$chatId/messages';
  static String chatMarkRead(String chatId) => '/chats/$chatId/read';
  static String chatDelete(String chatId) => '/chats/$chatId';
  static String chatUploadImage(String chatId) => '/chats/$chatId/images';

  // ---- Subscriptions & Payments (vendor only) ------------------------------
  static const String subscriptionStatus = '/subscriptions/status';
  static const String subscriptionTransactions = '/subscriptions/transactions';
  static const String subscriptionVoucherBalance = '/subscriptions/voucher-balance';
  static const String subscriptionPaystackCheckout = '/subscriptions/paystack/checkout'; // GET -> hosted checkout URL
  static const String subscriptionPaystackVerify = '/subscriptions/paystack/verify'; // POST { reference }
  static const String subscriptionEspeesPay = '/subscriptions/espees/pay'; // POST -> hosted checkout URL

  // ---- Notifications ----------------------------------------------------
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  // ---- Settings -----------------------------------------------------------
  static const String settings = '/settings';

  // ---- Calling (Agora) --------------------------------------------------
  static const String callingToken = '/calling/token';
  static const String callingInitiate = '/calling/initiate';
  static const String callingEnd = '/calling/end';

  // ---- Translation --------------------------------------------------------
  static const String translate = '/translate';
  static const String translateBatch = '/translate/batch';
  static String translateListing(String listingId) => '/translate/listing/$listingId';

  // ---- Business rules (mirrors backend-configured pricing) ----------------
  static const int subscriptionFeeNaira = 25000;
  static const int subscriptionFeeEspees = 10;
}
