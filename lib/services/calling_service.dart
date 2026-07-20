import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/call_session.dart';

/// Wraps the /calling/* routes from your API (Agora-based, matching your
/// existing sbrai_solutions app). The backend is responsible for
/// generating short-lived Agora RTC tokens server-side (holding the
/// Agora App Certificate) — this app never sees that certificate,
/// only the per-call token it's issued.
class CallingService {
  final _client = ApiClient.instance;

  /// Starts a call: tells the backend who's being called and what kind
  /// of call it is, so it can push an IncomingCall FCM push to the
  /// callee (see RealtimeService). CallingController::initiateCall()
  /// requires `recipient_id`, `call_type`, and `channel_name` — there is
  /// no server-side call record, so the channel name is generated
  /// client-side and is the only thing identifying this call session
  /// going forward (there's no `call_id` concept on the backend).
  Future<CallSession> initiateCall({
    required String calleeId,
    required CallType type,
    required String otherPartyName,
    String? otherPartyAvatarUrl,
  }) async {
    final channelName = _generateChannelName();
    final res = await _client.post(ApiConfig.callingInitiate, data: {
      'recipient_id': calleeId,
      'call_type': type == CallType.video ? 'video' : 'voice',
      'channel_name': channelName,
    });
    final session = CallSession.fromJson(res.data, otherPartyName: otherPartyName, otherPartyAvatarUrl: otherPartyAvatarUrl, otherPartyId: calleeId);
    // generateToken/initiateCall responses don't include a call_id (the
    // backend has none) — key the session on the channel name instead.
    return CallSession(
      callId: channelName,
      channelName: session.channelName.isNotEmpty ? session.channelName : channelName,
      agoraToken: session.agoraToken,
      uid: session.uid,
      type: type,
      otherPartyName: otherPartyName,
      otherPartyAvatarUrl: otherPartyAvatarUrl,
      otherPartyId: calleeId,
    );
  }

  /// Fetches a fresh Agora token for a call channel — used when
  /// accepting an incoming call (the caller already has one from
  /// initiateCall; the callee needs their own).
  Future<CallSession> getToken({
    required String channelName,
    required CallType type,
    required String otherPartyName,
    String? otherPartyAvatarUrl,
    String otherPartyId = '',
  }) async {
    final res = await _client.post(ApiConfig.callingToken, data: {
      'channel_name': channelName,
    });
    final session = CallSession.fromJson(res.data, otherPartyName: otherPartyName, otherPartyAvatarUrl: otherPartyAvatarUrl, otherPartyId: otherPartyId);
    return CallSession(
      callId: channelName,
      channelName: session.channelName.isNotEmpty ? session.channelName : channelName,
      agoraToken: session.agoraToken,
      uid: session.uid,
      type: type,
      otherPartyName: otherPartyName,
      otherPartyAvatarUrl: otherPartyAvatarUrl,
      otherPartyId: otherPartyId,
    );
  }

  /// CallingController::endCall() requires `recipient_id` + `channel_name`
  /// (there's no `call_id` on the backend to look a call up by).
  Future<void> endCall({required String recipientId, required String channelName}) async {
    await _client.post(ApiConfig.callingEnd, data: {
      'recipient_id': recipientId,
      'channel_name': channelName,
    });
  }

  String _generateChannelName() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'sbrai_$now';
  }
}
