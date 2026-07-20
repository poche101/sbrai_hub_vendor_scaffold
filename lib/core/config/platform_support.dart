import 'package:flutter/foundation.dart';

/// Central place to branch behavior across Android, iOS, and Windows
/// (the three deployment targets for this app). Uses
/// [defaultTargetPlatform] rather than dart:io's Platform so this file
/// works unmodified on web too, if that's ever added as a target.
class PlatformSupport {
  PlatformSupport._();

  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// google_sign_in / flutter_facebook_auth are mobile-first packages.
  /// Native Google/Facebook SDK sign-in isn't supported on Windows, so the
  /// social buttons fall back to email/password there instead of crashing
  /// on an unimplemented platform channel.
  static bool get supportsNativeSocialAuth => isMobile;

  /// webview_flutter has no Windows embedding today. Payment checkout
  /// falls back to opening the hosted Paystack/Espees page in the
  /// system browser via url_launcher on Windows, then the app re-checks
  /// subscription status when the user returns.
  static bool get supportsInAppWebView => !isWindows;

  /// pusher_channels_flutter (used for live chat updates over Laravel
  /// Reverb) targets Android/iOS. On Windows, ChatDetailScreen falls back
  /// to periodic polling instead of a live socket connection, so chat
  /// still works there — just not instantly.
  static bool get supportsRealtime => isMobile;

  /// agora_rtc_engine and permission_handler both ship official Windows
  /// support today (agora_rtc_engine: Android/iOS/macOS/Windows;
  /// permission_handler: via the permission_handler_windows federated
  /// plugin) — so calling isn't actually mobile-only. It just needs
  /// `flutter create` to have generated the windows/ folder and
  /// `flutter pub get` to have pulled those plugins in, same as any
  /// other platform. Not gated here.
  static bool get supportsCalling => !kIsWeb;
}
