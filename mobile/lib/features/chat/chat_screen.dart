import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/chat_conversation.dart';
import '../../core/models/chat_message.dart';
import '../../core/websocket/ws_client.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _conversationDetailProvider =
    FutureProvider.family<ChatConversation, int>(
        (ref, conversationId) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.conversations);
  final List list = resp.data is List ? resp.data as List : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  final conversations = list
      .map((e) =>
          ChatConversation.fromJson(e as Map<String, dynamic>))
      .toList();
  return conversations.firstWhere((c) => c.id == conversationId);
});

final _messagesProvider =
    FutureProvider.family<List<ChatMessage>, int>(
        (ref, conversationId) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(
      ApiEndpoints.conversationMessages(conversationId));
  final List list = resp.data is List ? resp.data as List : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list
      .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _localMessages = [];
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _connectWs();
  }

  Future<void> _connectWs() async {
    final ws = ref.read(wsClientProvider);
    await ws.connect();
    _wsSub = ws.messages.listen((data) {
      if (data['type'] == 'chat' &&
          data['conversationId'] == widget.conversationId) {
        final msg = ChatMessage(
          id: data['id'] as int? ?? 0,
          conversationId: widget.conversationId,
          senderId: data['senderId'] as int? ?? 0,
          content: data['content'] as String,
          createdAt: DateTime.now(),
        );
        setState(() => _localMessages.add(msg));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    ref.read(wsClientProvider).disconnect();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final me = ref.read(authProvider).user;
    final msg = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: widget.conversationId,
      senderId: me?.id ?? 0,
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() => _localMessages.add(msg));
    _scrollToBottom();
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(
        ApiEndpoints.conversationMessages(widget.conversationId),
        data: {'content': text},
      );
      // Also send via WebSocket for real-time delivery
      ref
          .read(wsClientProvider)
          .sendChatMessage(widget.conversationId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final convAsync =
        ref.watch(_conversationDetailProvider(widget.conversationId));
    final messagesAsync =
        ref.watch(_messagesProvider(widget.conversationId));
    final me = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: convAsync.when(
          loading: () => const Text('Chat'),
          error: (_, __) => const Text('Chat'),
          data: (conv) => Text(conv.otherUser.username),
        ),
      ),
      body: messagesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(_messagesProvider(widget.conversationId)),
        ),
        data: (initialMessages) {
          // Merge initial + local messages, deduplicate by id
          final allMessages = [
            ...initialMessages,
            ..._localMessages
                .where((m) => !initialMessages.any((i) => i.id == m.id))
          ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return Column(
            children: [
              Expanded(
                child: allMessages.isEmpty
                    ? const Center(
                        child: Text('Sin mensajes aún'))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: allMessages.length,
                        itemBuilder: (_, i) {
                          final msg = allMessages[
                              allMessages.length - 1 - i];
                          final isMe = msg.senderId == me?.id;
                          return _MessageBubble(
                              message: msg, isMe: isMe);
                        },
                      ),
              ),
              _InputBar(
                controller: _ctrl,
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF4FC3F7)
                    : const Color(0xFF16213E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      Radius.circular(isMe ? 16 : 4),
                  bottomRight:
                      Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.black87 : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send,
                  color: Color(0xFF4FC3F7)),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
