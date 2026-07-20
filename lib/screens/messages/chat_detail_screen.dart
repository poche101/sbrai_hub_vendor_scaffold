import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/config/platform_support.dart';
import '../../core/theme/app_colors.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../services/message_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/call_button.dart';

/// Handles two entry points:
///  - An existing conversation: pass [chatId] (+ ideally [sellerId],
///    [otherPartyName], [otherPartyAvatarUrl] so the header and call
///    buttons can render immediately).
///  - Starting a new one from a product page: pass [sellerId] (+ optional
///    [listingId]); a chat thread is created via POST /chats on first send.
class ChatDetailScreen extends StatefulWidget {
  final String? chatId;
  final String? sellerId;
  final String? listingId;
  final String? otherPartyName;
  final String? otherPartyAvatarUrl;

  const ChatDetailScreen({
    super.key,
    this.chatId,
    this.sellerId,
    this.listingId,
    this.otherPartyName,
    this.otherPartyAvatarUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageService = MessageService();
  final _inputController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _chatId;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  Future<void Function()>? _unsubscribeFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    if (_chatId != null) {
      _loadMessages();
      _startLiveUpdates();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _unsubscribeFuture?.then((unsub) => unsub());
    super.dispose();
  }

  void _startLiveUpdates() {
    if (_chatId == null) return;

    if (PlatformSupport.supportsRealtime) {
      _unsubscribeFuture =
          RealtimeService.instance.subscribeToChat(_chatId!, (data) {
        // A new message arrived over the socket — just reload from the
        // REST endpoint rather than trying to hand-construct a
        // ChatMessage from the raw event payload, so message ordering
        // and read state always match the server's source of truth.
        _loadMessages(silently: true);
      });
    } else {
      // Windows fallback: no realtime socket support, so poll instead.
      // Still "live" from the user's perspective, just on a short delay.
      _pollTimer = Timer.periodic(
          const Duration(seconds: 5), (_) => _loadMessages(silently: true));
    }
  }

  Future<void> _loadMessages({bool silently = false}) async {
    if (_chatId == null) return;
    if (!silently) setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id ?? '';
      final messages = await _messageService.getMessages(_chatId!, userId);
      if (mounted) setState(() => _messages = messages);
      await _messageService.markRead(_chatId!);
    } catch (_) {
      // leave whatever messages we already have
    } finally {
      if (mounted && !silently) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      if (_chatId == null) {
        // ChatController::store() creates the chat AND its first message
        // in a single call — there's no way to create an empty thread
        // first and send into it separately.
        _chatId = await _messageService.startChat(
          sellerId: widget.sellerId!,
          listingId: widget.listingId!,
          message: text,
        );
        _startLiveUpdates();
      } else {
        await _messageService.sendMessage(_chatId!, text);
      }
      _inputController.clear();
      await _loadMessages();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not send message. Please try again.')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Guards image sends against the backend constraint documented above:
  /// ChatController::store() only creates a chat together with its first
  /// *text* message, so there's no endpoint that can start a brand-new
  /// thread from an image alone. If [_chatId] is already set (existing
  /// conversation, or one just started via [_send]), this is a no-op.
  /// Otherwise it throws, and [_sendImage] surfaces a message asking the
  /// user to say hello first rather than silently failing against an
  /// endpoint that doesn't exist.
  Future<void> _ensureChatExists() async {
    if (_chatId != null) return;
    throw StateError('Send a text message first to start the conversation.');
  }

  Future<void> _sendImage() async {
    final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isSending = true);
    try {
      await _ensureChatExists();
      await _messageService.sendImage(_chatId!, File(picked.path));
      await _loadMessages();
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not send image. Please try again.')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.otherPartyName ?? 'Chat';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.sellerId != null)
            CallButtons(
              otherPartyId: widget.sellerId!,
              otherPartyName: title,
              otherPartyAvatarUrl: widget.otherPartyAvatarUrl,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Say hello 👋',
                            style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[_messages.length - 1 - i];
                          return Align(
                            alignment: m.isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75),
                              child: m.type == ChatMessageType.image &&
                                      m.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(m.imageUrl!,
                                          fit: BoxFit.cover),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: m.isMine
                                            ? AppColors.primary
                                            : const Color(0xFFF0F0F2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(m.body,
                                          style: TextStyle(
                                              color: m.isMine
                                                  ? Colors.white
                                                  : AppColors.textPrimary)),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    tooltip: _chatId == null
                        ? 'Send a message first to start the chat'
                        : 'Send a photo',
                    onPressed: _isSending ? null : _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration:
                          const InputDecoration(hintText: 'Type a message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
