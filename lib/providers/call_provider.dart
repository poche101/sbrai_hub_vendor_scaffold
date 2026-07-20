import 'package:flutter/material.dart';
import '../core/app_messenger.dart';
import '../core/config/platform_support.dart';
import '../models/call_session.dart';
import '../services/calling_service.dart';
import '../services/realtime_service.dart';
import '../screens/calling/call_screen.dart';
import '../screens/calling/incoming_call_screen.dart';

/// Owns the app-wide "is there a call happening" concern. Registers with
/// RealtimeService for incoming-call events as soon as it's constructed
/// (main.dart creates one instance for the whole app lifetime) and pushes
/// a full-screen incoming-call UI on top of whatever the user is
/// currently looking at, using the same navigatorKey AppMessenger uses.
class CallProvider extends ChangeNotifier {
  final _callingService = CallingService();

  CallProvider() {
    RealtimeService.instance.addIncomingCallListener(_handleIncomingCallEvent);
  }

  void _handleIncomingCallEvent(Map<String, dynamic> data) {
    if (!PlatformSupport.supportsCalling) return; // web only, currently

    final navigator = AppMessenger.navigatorKey.currentState;
    if (navigator == null) return;

    final callerId = (data['caller_id'] ?? '').toString();
    final callerName = data['caller_name']?.toString() ?? 'Unknown';
    final callerAvatar = data['caller_avatar']?.toString();
    final channelName = data['channel_name']?.toString() ?? '';
    // CallingController::initiateCall() pushes `call_type`, not `type`.
    final type = data['call_type'] == 'video' ? CallType.video : CallType.voice;

    navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => IncomingCallScreen(
          callerName: callerName,
          callerAvatarUrl: callerAvatar,
          type: type,
          onAccept: () async {
            Navigator.of(context).pop();
            final session = await _callingService.getToken(
              channelName: channelName,
              type: type,
              otherPartyName: callerName,
              otherPartyAvatarUrl: callerAvatar,
              otherPartyId: callerId,
            );
            navigator.push(MaterialPageRoute(
                builder: (_) => CallScreen(session: session)));
          },
          onDecline: () {
            Navigator.of(context).pop();
            if (callerId.isNotEmpty && channelName.isNotEmpty) {
              _callingService.endCall(
                  recipientId: callerId, channelName: channelName);
            }
          },
        ),
      ),
    );
  }

  /// Called from a Call button (chat header, product details) to start
  /// an outgoing call.
  Future<void> startCall(
    BuildContext context, {
    required String calleeId,
    required CallType type,
    required String otherPartyName,
    String? otherPartyAvatarUrl,
  }) async {
    if (!PlatformSupport.supportsCalling) {
      AppMessenger.showError(
          'Voice and video calling aren\'t available here yet.');
      return;
    }

    try {
      final session = await _callingService.initiateCall(
        calleeId: calleeId,
        type: type,
        otherPartyName: otherPartyName,
        otherPartyAvatarUrl: otherPartyAvatarUrl,
      );
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CallScreen(session: session)),
      );
    } catch (_) {
      AppMessenger.showError('Could not start the call. Please try again.');
    }
  }

  @override
  void dispose() {
    RealtimeService.instance
        .removeIncomingCallListener(_handleIncomingCallEvent);
    super.dispose();
  }
}
