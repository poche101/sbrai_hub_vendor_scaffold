/// ---------------------------------------------------------------------------
/// REALTIME (Pusher Channels) CONFIG
/// ---------------------------------------------------------------------------
/// This app connects to real hosted Pusher Channels (pusher.com), not a
/// self-hosted Laravel Reverb server — chosen so there's no broadcasting
/// server process to run/maintain ourselves. Fill these in from your
/// Pusher dashboard (Pusher Channels -> your app -> App Keys tab):
///
///   key      -> appKey below
///   cluster  -> cluster below (e.g. 'mt1', 'eu', 'ap1', 'us2')
///
/// These should match whatever your Laravel backend's config/broadcasting.php
/// 'pusher' connection is using (PUSHER_APP_KEY / PUSHER_APP_CLUSTER in
/// your backend's .env), since both sides need to agree on the same
/// Pusher app to talk to each other.
///
/// Private channels (chat threads, per-user notification channel) require
/// your Laravel app to have broadcasting auth wired up at
/// [broadcastAuthEndpoint] — this is Laravel's standard
/// `/broadcasting/auth` route from `routes/channels.php` +
/// `BroadcastServiceProvider`, protected by the same Sanctum bearer token
/// this app already sends on every other request. (Note: the actual auth
/// call in this app happens via the `onAuthorizer` callback in
/// RealtimeService, not by reading this constant directly — it's kept
/// here for reference/documentation.)
/// ---------------------------------------------------------------------------
class RealtimeConfig {
  RealtimeConfig._();

  /// TODO: fill in from your Pusher dashboard (App Keys -> key).
  static const String appKey = 'f67aacbb38667abced99';

  /// TODO: fill in from your Pusher dashboard (App Keys -> cluster).
  static const String cluster = 'eu';

  /// Laravel's standard broadcasting auth endpoint. Assumed to live at
  /// the API root (not under /v1) per Laravel's default
  /// BroadcastServiceProvider::routes() — adjust if yours is namespaced
  /// differently.
  static const String broadcastAuthEndpoint =
      'https://sbraisolutions.com/broadcasting/auth';
  // ---- Channel / event naming conventions this app expects -----------------
  // Adjust these to match your actual Laravel broadcast event classes if
  // they differ (i.e. whatever you pass to broadcastAs() / the channel
  // name your event's broadcastOn() returns).
  static String chatChannel(String chatId) => 'private-chat.$chatId';
  static String userChannel(String userId) => 'private-user.$userId';

  static const String eventMessageSent = 'MessageSent';
  static const String eventIncomingCall = 'IncomingCall';
  static const String eventCallEnded = 'CallEnded';
}
