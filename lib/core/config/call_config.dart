/// ---------------------------------------------------------------------------
/// AGORA (voice/video calling) CONFIG
/// ---------------------------------------------------------------------------
/// Matches the Agora setup your existing sbrai_solutions app already uses.
/// The App ID is safe to ship in the client (it's not a secret — Agora's
/// security model relies on the short-lived token issued per-call by your
/// backend's POST /calling/token, not the App ID itself).
/// ---------------------------------------------------------------------------
class CallConfig {
  CallConfig._();

  /// TODO: fill in your Agora App ID (same one used in sbrai_solutions).
  static const String agoraAppId = 'REPLACE_WITH_AGORA_APP_ID';
}
