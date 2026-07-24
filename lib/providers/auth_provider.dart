import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/social_auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _socialAuthService = SocialAuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? errorMessage;
  bool isLoading = false;

  AuthProvider() {
    ApiClient.instance.onUnauthorized = _handleUnauthorized;
    _restoreSession();
  }

  bool get isLoggedIn =>
      status == AuthStatus.authenticated && currentUser != null;
  bool get isVendor => currentUser?.isVendor ?? false;
  bool get isBuyer => currentUser?.role == UserRole.buyer;
  bool get isAdmin => currentUser?.role == UserRole.admin;

  Future<void> _restoreSession() async {
    final token = await TokenStorage.instance.getToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _authService.me();
      status = AuthStatus.authenticated;
      RealtimeService.instance.connect(userId: currentUser!.id);
    } catch (_) {
      await TokenStorage.instance.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void _handleUnauthorized() async {
    await TokenStorage.instance.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    RealtimeService.instance.disconnect();
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      status = AuthStatus.authenticated;
      return true;
    } catch (e, stackTrace) {
      // 🚨 Print full details directly to your terminal log!
      debugPrint('================ 🛑 AUTH ERROR 🛑 ================');
      debugPrint('Error: $e');
      debugPrint('StackTrace:\n$stackTrace');
      debugPrint('===================================================');

      errorMessage = _friendly(e);
      status = AuthStatus.unauthenticated;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    return s.contains('displayMessage') ? s : s.replaceFirst('Exception: ', '');
  }

  Future<bool> loginBuyerOrVendor({
    required String email,
    required String password,
    required bool termsAccepted,
  }) {
    return _runAuthAction(() async {
      if (!termsAccepted) {
        throw Exception(
            'You must accept the Terms of Service and Privacy Policy to continue.');
      }
      final result = await _authService.login(email: email, password: password);
      await _persistSession(result);
    });
  }

  Future<bool> registerBuyer({
    required String fullName,
    required String email,
    required String phone,
    String? address,
    required String password,
    required bool termsAccepted,
  }) {
    return _runAuthAction(() async {
      if (!termsAccepted) {
        throw Exception(
            'You must accept the Terms of Service and Privacy Policy to continue.');
      }
      final result = await _authService.registerBuyer(
        fullName: fullName,
        email: email,
        phone: phone,
        address: address,
        password: password,
      );
      await _persistSession(result);
    });
  }

  Future<bool> registerVendor({
    required String fullName,
    required String email,
    required String phone,
    required String businessName,
    String? businessId,
    required String businessAddress,
    required String password,
    required bool termsAccepted,
  }) {
    return _runAuthAction(() async {
      if (!termsAccepted) {
        throw Exception(
            'You must accept the Terms of Service and Privacy Policy to continue.');
      }
      final result = await _authService.registerVendor(
        fullName: fullName,
        email: email,
        phone: phone,
        businessName: businessName,
        businessId: businessId,
        businessAddress: businessAddress,
        password: password,
      );
      await _persistSession(result);
    });
  }

  Future<bool> continueWithGoogle(
      {required String role, required bool termsAccepted}) {
    return _runAuthAction(() async {
      if (!termsAccepted) {
        throw Exception(
            'You must accept the Terms of Service and Privacy Policy to continue.');
      }

      final tokens = await _socialAuthService.signInWithGoogle();

      // Fix: Throw an error instead of silently returning so the catch block handles it
      if (tokens == null ||
          (tokens.idToken == null && tokens.accessToken == null)) {
        throw Exception(
            'Google sign-in was cancelled or failed to initialize.');
      }

      final result = await _authService.googleAuth(
        idToken: tokens.idToken ?? '',
        accessToken: tokens.accessToken,
        role: role,
      );
      await _persistSession(result);
    });
  }

  Future<bool> continueWithFacebook(
      {required String role, required bool termsAccepted}) {
    return _runAuthAction(() async {
      if (!termsAccepted) {
        throw Exception(
            'You must accept the Terms of Service and Privacy Policy to continue.');
      }

      final token = await _socialAuthService.signInWithFacebook();

      // Fix: Throw an error instead of silently returning so the catch block handles it
      if (token == null) {
        throw Exception(
            'Facebook sign-in was cancelled or failed to initialize.');
      }

      final result =
          await _authService.facebookAuth(accessToken: token, role: role);
      await _persistSession(result);
    });
  }

  Future<void> _persistSession(AuthResult result) async {
    await TokenStorage.instance.saveToken(result.token);
    await TokenStorage.instance.saveRole(result.user.role.name);
    await TokenStorage.instance.setTermsAccepted(true);
    currentUser = result.user;
    RealtimeService.instance.connect(userId: result.user.id);
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // best-effort; still clear local session
    }
    await TokenStorage.instance.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    RealtimeService.instance.disconnect();
    notifyListeners();
  }

  /// Permanently deletes the account via DELETE /auth/account, then
  /// clears the local session the same way logout() does.
  Future<bool> deleteAccount() async {
    try {
      await _authService.deleteAccount();
    } catch (e) {
      errorMessage = 'Could not delete your account. Please try again.';
      notifyListeners();
      return false;
    }
    await TokenStorage.instance.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    RealtimeService.instance.disconnect();
    notifyListeners();
    return true;
  }

  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) {
    return _authService.changePassword(
        currentPassword: currentPassword, newPassword: newPassword);
  }

  /// Updates the profile via PUT /auth/profile and refreshes the locally
  /// cached user so screens (Profile, Home role badge, etc.) reflect the
  /// change immediately without needing a full re-login.
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    try {
      currentUser = await _authService.updateProfile(fields);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Could not update your profile. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Uploads a new profile photo via multipart request and refreshes the
  /// locally cached user so screens (Profile, Drawer, etc.) reflect the
  /// change immediately without needing a full re-login.
  Future<bool> updateProfilePhoto(File photo) async {
    try {
      currentUser = await _authService.uploadAvatar(photo);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Could not update your profile photo. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
