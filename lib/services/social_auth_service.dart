import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Result of a native Google sign-in — the backend's POST /auth/google
/// accepts either field, so we pass both along.
class GoogleAuthTokens {
  final String? idToken;
  final String? accessToken;
  GoogleAuthTokens({this.idToken, this.accessToken});
}

/// Handles the *client-side* half of social login: getting a token from
/// Google/Facebook's native SDKs, which is then sent to the backend
/// (POST /auth/google or /auth/facebook) for verification + our own app
/// token issuance.
///
/// Setup required on your end:
///  - Google: add google-services.json (Android) / GoogleService-Info.plist
///    (iOS) and register the OAuth client ID matching your Firebase project
///    (`sbrai-solutions-api`) and Web Client ID
///    247352594282-ngifekbhv3s8q078tm6cofc29l2slvmo.
///  - Facebook: register Facebook App ID 1925652658114001 in
///    android/app/src/main/res/values/strings.xml and Info.plist.
class SocialAuthService {
  final _google = GoogleSignIn(scopes: ['email', 'profile']);

  Future<GoogleAuthTokens?> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null; // user cancelled
    final auth = await account.authentication;
    return GoogleAuthTokens(idToken: auth.idToken, accessToken: auth.accessToken);
  }

  Future<void> signOutGoogle() => _google.signOut();

  Future<String?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(permissions: ['email', 'public_profile']);
    if (result.status != LoginStatus.success) return null;
    return result.accessToken?.tokenString;
  }

  Future<void> signOutFacebook() => FacebookAuth.instance.logOut();
}
