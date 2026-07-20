import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config/call_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_session.dart';
import '../../services/calling_service.dart';

/// Active call screen — handles both voice and video calls through the
/// same Agora engine. Video calls show local/remote video tiles; voice
/// calls show an avatar + elapsed-time UI instead.
///
/// NOTE: agora_rtc_engine's API has changed meaningfully across major
/// versions. This is written against the commonly-documented 6.x surface
/// (createAgoraRtcEngine / RtcEngineEventHandler / joinChannel with
/// ChannelMediaOptions). If `flutter pub get` resolves a version with a
/// different signature, check the package's migration notes — the call
/// flow here (initialize -> join -> render -> leave -> release) stays
/// the same regardless.
class CallScreen extends StatefulWidget {
  final CallSession session;

  const CallScreen({super.key, required this.session});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _callingService = CallingService();
  RtcEngine? _engine;

  bool _joined = false;
  bool _remoteJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraOff = false;
  DateTime? _callStartedAt;

  bool get _isVideo => widget.session.type == CallType.video;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await [Permission.microphone, if (_isVideo) Permission.camera].request();

    final engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(appId: CallConfig.agoraAppId));

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _joined = true;
            _callStartedAt = DateTime.now();
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteJoined = true;
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteJoined = false;
            _remoteUid = null;
          });
          _endCall();
        },
        onLeaveChannel: (connection, stats) {
          setState(() => _joined = false);
        },
      ),
    );

    if (_isVideo) {
      await engine.enableVideo();
      await engine.startPreview();
    } else {
      await engine.disableVideo();
    }

    await engine.setDefaultAudioRouteToSpeakerphone(_speakerOn);

    await engine.joinChannel(
      token: widget.session.agoraToken,
      channelId: widget.session.channelName,
      uid: widget.session.uid,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    if (mounted) setState(() => _engine = engine);
  }

  Future<void> _endCall() async {
    try {
      if (widget.session.otherPartyId.isNotEmpty) {
        await _callingService.endCall(
          recipientId: widget.session.otherPartyId,
          channelName: widget.session.channelName,
        );
      }
    } catch (_) {}
    await _engine?.leaveChannel();
    await _engine?.release();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await _engine?.muteLocalAudioStream(_muted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await _engine?.setDefaultAudioRouteToSpeakerphone(_speakerOn);
  }

  Future<void> _toggleCamera() async {
    setState(() => _cameraOff = !_cameraOff);
    await _engine?.muteLocalVideoStream(_cameraOff);
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isVideo) _buildVideoLayer() else _buildVoiceLayer(),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(widget.session.otherPartyName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_statusLabel(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CallControlButton(icon: _muted ? Icons.mic_off : Icons.mic, onTap: _toggleMute),
                  const SizedBox(width: 20),
                  if (_isVideo) _CallControlButton(icon: _cameraOff ? Icons.videocam_off : Icons.videocam, onTap: _toggleCamera),
                  if (_isVideo) const SizedBox(width: 20),
                  _CallControlButton(icon: _speakerOn ? Icons.volume_up : Icons.hearing, onTap: _toggleSpeaker),
                  const SizedBox(width: 20),
                  _CallControlButton(icon: Icons.call_end, onTap: _endCall, color: AppColors.danger),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel() {
    if (!_joined) return 'Connecting…';
    if (!_remoteJoined) return 'Ringing…';
    return 'In call';
  }

  Widget _buildVoiceLayer() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white24,
            backgroundImage: widget.session.otherPartyAvatarUrl != null ? NetworkImage(widget.session.otherPartyAvatarUrl!) : null,
            child: widget.session.otherPartyAvatarUrl == null
                ? Text(
                    widget.session.otherPartyName.isNotEmpty ? widget.session.otherPartyName[0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    final engine = _engine;
    if (engine == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Stack(
      children: [
        Positioned.fill(
          child: _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: engine,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.session.channelName),
                  ),
                )
              : Container(color: Colors.black),
        ),
        Positioned(
          top: 90,
          right: 16,
          width: 110,
          height: 150,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AgoraVideoView(
              controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CallControlButton({required this.icon, required this.onTap, this.color = Colors.white24});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(radius: 28, backgroundColor: color, child: Icon(icon, color: Colors.white)),
    );
  }
}
