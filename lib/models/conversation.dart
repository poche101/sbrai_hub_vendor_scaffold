class Conversation {
  final String id;
  final String otherPartyName;
  final String? otherPartyId;
  final String? otherPartyAvatarUrl;
  final bool otherPartyIsVendor;
  final String? listingTitle;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.otherPartyName,
    this.otherPartyId,
    this.otherPartyAvatarUrl,
    this.otherPartyIsVendor = false,
    this.listingTitle,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'].toString(),
      otherPartyName: json['other_user_name'] ?? '',
      otherPartyId: json['other_user_id']?.toString(),
      otherPartyAvatarUrl: json['other_user_avatar'],
      otherPartyIsVendor: json['other_user_is_vendor'] ?? false,
      listingTitle: json['listing_title'],
      lastMessage: json['last_message'] ?? '',
      lastMessageAt: DateTime.tryParse(json['last_message_time'] ?? '') ?? DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

enum ChatMessageType { text, image }

class ChatMessage {
  final String id;
  final String senderId;
  final String body;
  final ChatMessageType type;
  final String? imageUrl;
  final DateTime sentAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    this.type = ChatMessageType.text,
    this.imageUrl,
    required this.sentAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final imageUrl = json['image_url'] as String?;
    return ChatMessage(
      id: json['id'].toString(),
      senderId: json['sender_id'].toString(),
      body: json['content'] ?? '',
      type: (json['type'] == 'image' || (imageUrl != null && imageUrl.isNotEmpty)) ? ChatMessageType.image : ChatMessageType.text,
      imageUrl: imageUrl,
      sentAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isMine: json['sender_id'].toString() == currentUserId,
    );
  }
}
