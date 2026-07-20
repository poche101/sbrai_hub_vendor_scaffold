import 'dart:io';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';

class AuthResult {
  final String token;
  final AppUser user;
  AuthResult(this.token, this.user);
}

class AuthService {
  final _client = ApiClient.instance;

  Future<AuthResult> registerBuyer({
    required String fullName,
    required String email,
    required String phone,
    String? address,
    required String password,
  }) async {
    final res = await _client.post(ApiConfig.register, data: {
      'role': 'buyer',
      'full_name': fullName,
      'email': email,
      'phone': phone,
      if (address != null) 'address': address,
      'password': password,
      'password_confirmation': password,
    });
    return _parseAuthResponse(res.data);
  }

  Future<AuthResult> registerVendor({
    required String fullName,
    required String email,
    required String phone,
    required String businessName,
    String? businessId,
    required String businessAddress,
    required String password,
  }) async {
    final res = await _client.post(ApiConfig.register, data: {
      'role': 'vendor',
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'business_name': businessName,
      'cac_number': businessId,
      'business_address': businessAddress,
      'password': password,
      'password_confirmation': password,
    });
    return _parseAuthResponse(res.data);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final res = await _client.post(ApiConfig.login, data: {
      'email': email,
      'password': password,
    });
    return _parseAuthResponse(res.data);
  }

  /// POST /auth/google — sends both id_token and access_token since Laravel
  /// Socialite / Google API verification can use either; the backend should
  /// simply pick whichever field it validates against.
  Future<AuthResult> googleAuth({
    required String idToken,
    String? accessToken,
    required String role,
  }) async {
    final res = await _client.post(ApiConfig.googleAuth, data: {
      'id_token': idToken,
      if (accessToken != null) 'access_token': accessToken,
      'role': role,
    });
    return _parseAuthResponse(res.data);
  }

  /// POST /auth/facebook
  Future<AuthResult> facebookAuth({required String accessToken, required String role}) async {
    final res = await _client.post(ApiConfig.facebookAuth, data: {
      'access_token': accessToken,
      'role': role,
    });
    return _parseAuthResponse(res.data);
  }

  Future<void> logout() async {
    await _client.post(ApiConfig.logout);
  }

  /// AuthController::me() returns the user under a `user` key, not `data`.
  Future<AppUser> me() async {
    final res = await _client.get(ApiConfig.me);
    return AppUser.fromJson(Map<String, dynamic>.from(res.data['user'] ?? res.data['data'] ?? res.data));
  }

  Future<AppUser> updateProfile(Map<String, dynamic> fields) async {
    final res = await _client.put(ApiConfig.updateProfile, data: fields);
    return AppUser.fromJson(Map<String, dynamic>.from(res.data['user'] ?? res.data['data'] ?? res.data));
  }

  Future<void> uploadAvatar(File image) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(image.path, filename: 'avatar.jpg'),
    });
    await _client.postMultipart(ApiConfig.uploadAvatar, formData);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post(ApiConfig.changePassword, data: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPassword,
    });
  }

  /// Step 1 of password reset — Laravel sends an email containing a
  /// reset token/link. The user copies the token into the app (or it's
  /// deep-linked in a future update) for step 2 below.
  Future<void> requestPasswordReset(String email) async {
    await _client.post(ApiConfig.forgotPassword, data: {'email': email});
  }

  /// Step 2 — submit the token from the reset email along with a new
  /// password.
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    await _client.post(ApiConfig.resetPassword, data: {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<void> resendConfirmationEmail() async {
    await _client.post(ApiConfig.resendConfirmation);
  }

  Future<void> deleteAccount() async {
    await _client.delete(ApiConfig.deleteAccount);
  }

  Future<void> updateFcmToken(String token) async {
    await _client.post(ApiConfig.fcmToken, data: {'fcm_token': token});
  }

  AuthResult _parseAuthResponse(dynamic data) {
    final map = data is Map ? data : {};
    final token = map['token'] ?? map['access_token'] ?? map['data']?['token'];
    final userJson = map['user'] ?? map['data']?['user'] ?? map['data'];
    return AuthResult(token.toString(), AppUser.fromJson(Map<String, dynamic>.from(userJson)));
  }
}
