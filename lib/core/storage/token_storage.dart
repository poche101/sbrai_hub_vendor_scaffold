import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage so the rest of the app never touches
/// platform storage APIs directly.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'sbrai_auth_token';
  static const _roleKey = 'sbrai_user_role';
  static const _termsKey = 'sbrai_terms_accepted';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveRole(String role) => _storage.write(key: _roleKey, value: role);
  Future<String?> getRole() => _storage.read(key: _roleKey);

  Future<void> setTermsAccepted(bool accepted) =>
      _storage.write(key: _termsKey, value: accepted.toString());
  Future<bool> getTermsAccepted() async =>
      (await _storage.read(key: _termsKey)) == 'true';

  Future<void> clear() => _storage.deleteAll();
}
