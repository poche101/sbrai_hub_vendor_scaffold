import 'dart:io';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/conversation.dart';

/// Wraps the /chats endpoints (Laravel's ChatController).
class MessageService {
  final _client = ApiClient.instance;

  Future<List<Conversation>> getConversations() async {
    final res = await _client.get(ApiConfig.chats);
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => Conversation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Starts (or fetches an existing) chat thread with a seller about a
  /// specific listing — POST /chats. ChatController::store() requires
  /// `vendor_id` (not `recipient_id`), `listing_id`, and an opening
  /// `message` — it's not a bare thread-creation call.
  Future<String> startChat({required String sellerId, required String listingId, required String message}) async {
    final res = await _client.post(ApiConfig.chats, data: {
      'vendor_id': sellerId,
      'listing_id': listingId,
      'message': message,
    });
    final data = res.data['data'] ?? res.data['chat'] ?? res.data;
    return (data['id'] ?? data['chat_id']).toString();
  }

  Future<List<ChatMessage>> getMessages(String chatId, String currentUserId) async {
    final res = await _client.get(ApiConfig.chatMessages(chatId));
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e), currentUserId)).toList();
  }

  /// ChatController::sendMessage() validates `content`, not `body`.
  Future<void> sendMessage(String chatId, String content) async {
    await _client.post(ApiConfig.chatMessages(chatId), data: {'content': content});
  }

  Future<void> sendImage(String chatId, File image) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: 'chat_image.jpg'),
    });
    await _client.postMultipart(ApiConfig.chatUploadImage(chatId), formData);
  }

  Future<void> markRead(String chatId) async {
    await _client.post(ApiConfig.chatMarkRead(chatId));
  }

  Future<void> deleteChat(String chatId) async {
    await _client.delete(ApiConfig.chatDelete(chatId));
  }
}
