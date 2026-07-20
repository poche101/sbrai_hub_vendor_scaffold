import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/conversation.dart';
import '../../providers/locale_provider.dart';
import '../../services/message_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _messageService = MessageService();
  final _searchController = TextEditingController();
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _messageService.getConversations();
      setState(() => _conversations = result);
    } catch (_) {
      // keep list empty; the UI below shows an empty state
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Conversation> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _conversations;
    return _conversations.where((c) => c.otherPartyName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(locale.t('messages'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Search conversations...', prefixIcon: Icon(Icons.search)),
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_filtered.isEmpty)
              const Expanded(
                child: Center(child: Text('No conversations yet.', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = _filtered[i];
                    return Card(
                      child: ListTile(
                        onTap: () => context.push(
                          '/messages/${c.id}?otherPartyId=${c.otherPartyId ?? ''}&otherPartyName=${Uri.encodeComponent(c.otherPartyName)}&otherPartyAvatar=${Uri.encodeComponent(c.otherPartyAvatarUrl ?? '')}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: c.otherPartyAvatarUrl != null ? NetworkImage(c.otherPartyAvatarUrl!) : null,
                          child: c.otherPartyAvatarUrl == null
                              ? Text(c.otherPartyName.isNotEmpty ? c.otherPartyName[0] : '?', style: const TextStyle(color: AppColors.primary))
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(child: Text(c.otherPartyName, overflow: TextOverflow.ellipsis)),
                            if (c.otherPartyIsVendor) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(6)),
                                child: const Text('Vendor', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.listingTitle != null)
                              Text(c.listingTitle!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_relativeTime(c.lastMessageAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            if (c.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              CircleAvatar(radius: 10, backgroundColor: AppColors.primary, child: Text('${c.unreadCount}', style: const TextStyle(fontSize: 11, color: Colors.white))),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
