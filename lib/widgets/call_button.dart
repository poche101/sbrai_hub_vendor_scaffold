import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_session.dart';
import '../providers/call_provider.dart';

/// Voice/video call icon buttons — used in the chat screen's AppBar to
/// call whoever you're messaging. Hidden entirely on platforms that
/// don't support calling (see PlatformSupport.supportsCalling — web,
/// currently) rather than shown non-functional.
class CallButtons extends StatelessWidget {
  final String otherPartyId;
  final String otherPartyName;
  final String? otherPartyAvatarUrl;

  const CallButtons({
    super.key,
    required this.otherPartyId,
    required this.otherPartyName,
    this.otherPartyAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final callProvider = context.read<CallProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.call_outlined),
          tooltip: 'Voice call',
          onPressed: () => callProvider.startCall(
            context,
            calleeId: otherPartyId,
            type: CallType.voice,
            otherPartyName: otherPartyName,
            otherPartyAvatarUrl: otherPartyAvatarUrl,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          tooltip: 'Video call',
          onPressed: () => callProvider.startCall(
            context,
            calleeId: otherPartyId,
            type: CallType.video,
            otherPartyName: otherPartyName,
            otherPartyAvatarUrl: otherPartyAvatarUrl,
          ),
        ),
      ],
    );
  }
}
