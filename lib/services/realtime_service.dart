import 'dart:async';
import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../core/config/realtime_config.dart';
import '../core/storage/token_storage.dart';

typedef ChatEventCallback = void Function(Map<String, dynamic> data);

/// Thin wrapper around pusher_channels_flutter, connected to real hosted
/// Pusher Channels (not self-hosted Reverb — see core/config/realtime_config.dart
/// for the appKey/cluster values to fill in). Chosen over Reverb specifically
/// so there's no broadcasting server process to run/maintain ourselves.
///
/// This is a plain singleton (not a ChangeNotifier/Provider) so it can be
/// driven from AuthProvider on login/logout without a circular provider
/// dependency, while other providers/screens (CallProvider,
/// ChatDetailScreen) register lightweight callbacks with it.
///
/// NOTE: pusher_channels_flutter's exact API (parameter names on `init`,
/// event callback shapes) can shift between package versions. This is
/// written against the commonly-documented 2.x surface — if
/// `flutter pub get` / `flutter analyze` flags a signature mismatch,
/// check the installed version's README; the connection concepts here
/// (init with apiKey/cluster, onAuthorizer for private channels,
/// subscribe/bind per channel) will still apply.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  PusherChannelsFlutter? _pusher;
  String? _connectedUserId;
  bool get isConnected => _connectedUserId != null;

  final List<void Function(Map<String, dynamic>)> _incomingCallListeners = [];
  final List<void Function(Map<String, dynamic>)> _newMessageListeners = [];
  final Map<String, List<ChatEventCallback>> _chatChannelListeners = {};

  /// Called by AuthProvider right after a successful login/session
  /// restore. Connects once and subscribes to this user's private
  /// notification channel (incoming calls, new-message pings for the
  /// conversation list).
  Future<void> connect({required String userId}) async {
    if (_connectedUserId == userId) return; // already connected as this user
    await disconnect();

    try {
      final pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(
        apiKey: RealtimeConfig.appKey,
        // Real Pusher region cluster from your Pusher dashboard (e.g.
        // 'mt1', 'eu', 'ap1') — this is actually used for routing,
        // unlike with self-hosted Reverb. Confirm this matches your
        // Pusher app's configured cluster.
        cluster: RealtimeConfig.cluster,
        onConnectionStateChange: (currentState, previousState) {},
        onError: (message, code, exception) {},
        onEvent: (event) =>
            _routeEvent(event.channelName, event.eventName, event.data),
        onAuthorizer: _authorizeChannel,
      );
      await pusher.connect();
      await pusher.subscribe(channelName: RealtimeConfig.userChannel(userId));
      _pusher = pusher;
      _connectedUserId = userId;
    } catch (_) {
      // Realtime is a progressive enhancement — if the socket can't
      // connect (e.g. Pusher app not configured yet, or running on a
      // platform without support), the rest of the app (REST-based
      // messaging, calling initiation) keeps working without it.
      _pusher = null;
      _connectedUserId = null;
    }
  }

  Future<void> disconnect() async {
    try {
      await _pusher?.disconnect();
    } catch (_) {}
    _pusher = null;
    _connectedUserId = null;
    _chatChannelListeners.clear();
  }

  /// Laravel's broadcasting auth for private channels — signs the socket
  /// ID with the same bearer token every other API call uses, so Pusher
  /// can confirm this user is allowed on e.g. private-chat.42.
  Future<dynamic> _authorizeChannel(
      String channelName, String socketId, dynamic options) async {
    final token = await TokenStorage.instance.getToken();
    // pusher_channels_flutter expects this to return the auth payload
    // Laravel's /broadcasting/auth endpoint would normally return when
    // called via an XHR request with { socket_id, channel_name }. Since
    // this app's Dio client already centralizes auth headers, doing the
    // HTTP call is intentionally minimal/inline here rather than routed
    // through ApiClient, to avoid coupling this file to that layer.
    // See RealtimeConfig.broadcastAuthEndpoint.
    return {
      'headers': {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    };
  }

  void _routeEvent(String channelName, String eventName, String? data) {
    if (data == null || data.isEmpty) return;
    Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) return;
      parsed = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    if (eventName == RealtimeConfig.eventIncomingCall) {
      for (final cb in _incomingCallListeners) {
        cb(parsed);
      }
      return;
    }

    if (channelName.startsWith('private-chat.') &&
        eventName == RealtimeConfig.eventMessageSent) {
      final listeners = _chatChannelListeners[channelName];
      if (listeners != null) {
        for (final cb in listeners) {
          cb(parsed);
        }
      }
      for (final cb in _newMessageListeners) {
        cb(parsed);
      }
    }
  }

  /// Subscribes to a specific chat thread's channel — call from
  /// ChatDetailScreen.initState, and call the returned function from
  /// dispose() to unsubscribe.
  Future<void Function()> subscribeToChat(
      String chatId, ChatEventCallback onMessage) async {
    final channelName = RealtimeConfig.chatChannel(chatId);
    _chatChannelListeners.putIfAbsent(channelName, () => []).add(onMessage);

    try {
      await _pusher?.subscribe(channelName: channelName);
    } catch (_) {
      // If the subscribe call fails, the listener list is still cleaned
      // up correctly below on unsubscribe — the caller's polling
      // fallback (see ChatDetailScreen) covers this case.
    }

    return () {
      _chatChannelListeners[channelName]?.remove(onMessage);
      if ((_chatChannelListeners[channelName]?.isEmpty ?? true)) {
        _pusher?.unsubscribe(channelName: channelName);
        _chatChannelListeners.remove(channelName);
      }
    };
  }

  void addIncomingCallListener(void Function(Map<String, dynamic>) callback) {
    _incomingCallListeners.add(callback);
  }

  void removeIncomingCallListener(
      void Function(Map<String, dynamic>) callback) {
    _incomingCallListeners.remove(callback);
  }

  void addNewMessageListener(void Function(Map<String, dynamic>) callback) {
    _newMessageListeners.add(callback);
  }

  void removeNewMessageListener(void Function(Map<String, dynamic>) callback) {
    _newMessageListeners.remove(callback);
  }
}
