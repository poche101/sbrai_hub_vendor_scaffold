enum CallType { voice, video }

/// Everything needed to join an Agora channel for one call, plus display
/// info for the call/incoming-call screens.
class CallSession {
  final String callId;
  final String channelName;
  final String agoraToken;
  final int uid;
  final CallType type;
  final String otherPartyName;
  final String? otherPartyAvatarUrl;
  final String otherPartyId;

  CallSession({
    required this.callId,
    required this.channelName,
    required this.agoraToken,
    required this.uid,
    required this.type,
    required this.otherPartyName,
    this.otherPartyAvatarUrl,
    this.otherPartyId = '',
  });

  factory CallSession.fromJson(Map<String, dynamic> json, {required String otherPartyName, String? otherPartyAvatarUrl, String otherPartyId = ''}) {
    final data = json['data'] ?? json;
    return CallSession(
      callId: (data['call_id'] ?? data['id'] ?? '').toString(),
      channelName: data['channel_name'] ?? data['channel'] ?? '',
      agoraToken: data['token'] ?? data['agora_token'] ?? '',
      uid: data['uid'] is int ? data['uid'] : int.tryParse('${data['uid']}') ?? 0,
      type: (data['type'] == 'video') ? CallType.video : CallType.voice,
      otherPartyName: otherPartyName,
      otherPartyAvatarUrl: otherPartyAvatarUrl,
      otherPartyId: otherPartyId,
    );
  }
}
