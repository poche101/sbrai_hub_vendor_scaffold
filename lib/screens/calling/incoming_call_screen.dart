import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_session.dart';

/// Full-screen incoming call UI, pushed by CallProvider on top of
/// whatever the user was looking at when the call comes in.
class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String? callerAvatarUrl;
  final CallType type;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    this.callerAvatarUrl,
    required this.type,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // don't let a back-swipe silently dismiss an incoming call
      child: Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  type == CallType.video ? 'Incoming Video Call' : 'Incoming Voice Call',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white24,
                  backgroundImage: callerAvatarUrl != null ? NetworkImage(callerAvatarUrl!) : null,
                  child: callerAvatarUrl == null
                      ? Text(callerName.isNotEmpty ? callerName[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(height: 16),
                Text(callerName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: onDecline,
                          child: const CircleAvatar(radius: 32, backgroundColor: AppColors.danger, child: Icon(Icons.call_end, color: Colors.white, size: 28)),
                        ),
                        const SizedBox(height: 8),
                        const Text('Decline', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: onAccept,
                          child: const CircleAvatar(radius: 32, backgroundColor: AppColors.success, child: Icon(Icons.call, color: Colors.white, size: 28)),
                        ),
                        const SizedBox(height: 8),
                        const Text('Accept', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
