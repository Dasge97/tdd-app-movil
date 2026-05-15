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
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _conversationDetailProvider =
    FutureProvider.family<ChatConversation, int>((ref, conversationId) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get('${ApiEndpoints.conversations}/$conversationId');
  return ChatConversation.fromJson(resp.data as Map<String, dynamic>);
});

final _messagesProvider =
    FutureProvider.family<List<ChatMessage>, int>((ref, conversationId) async {
  final dio = ref.read(apiClientProvider);
  final resp =
      await dio.get(ApiEndpoints.conversationMessages(conversationId));
  final List list = resp.data is List
      ? resp.data as List
      : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
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
      if (data['type'] != 'chat_message') return;
      final payload = data['message'] as Map<String, dynamic>?;
      if (payload == null) return;
      if (payload['conversationId'] != widget.conversationId) return;
      try {
        final msg = ChatMessage.fromJson(payload);
        setState(() => _localMessages.add(msg));
        _scrollToBottom();
      } catch (_) {}
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
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
    final tempMsg = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: widget.conversationId,
      senderId: me?.id ?? 0,
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() => _localMessages.add(tempMsg));
    _scrollToBottom();
    try {
      final dio = ref.read(apiClientProvider);
      final resp = await dio.post(
        ApiEndpoints.conversationMessages(widget.conversationId),
        data: {'content': text},
      );
      final persisted = ChatMessage.fromJson(resp.data as Map<String, dynamic>);
      setState(() {
        _localMessages.removeWhere((m) => m.id == tempMsg.id);
        _localMessages.add(persisted);
      });
      ref.read(wsClientProvider).sendChatMessage(
            widget.conversationId,
            text,
            messageId: persisted.id,
            createdAt: persisted.createdAt,
          );
    } catch (e) {
      setState(() => _localMessages.removeWhere((m) => m.id == tempMsg.id));
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
    final messagesAsync = ref.watch(_messagesProvider(widget.conversationId));
    final me = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: TddColors.text2),
        title: convAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (conv) => Text(
            conv.otherUser.username,
            style: TddTypography.sans(size: 15, weight: FontWeight.w500),
          ),
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
          final allMessages = [
            ...initialMessages,
            ..._localMessages
                .where((m) => !initialMessages.any((i) => i.id == m.id)),
          ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return Column(
            children: [
              Expanded(
                child: allMessages.isEmpty
                    ? Center(
                        child: Text(
                          'Sin mensajes aún.',
                          style: TddTypography.sans(
                              size: 14, color: TddColors.text3),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        itemCount: allMessages.length,
                        itemBuilder: (_, i) {
                          final msg =
                              allMessages[allMessages.length - 1 - i];
                          return _Bubble(
                              message: msg, isMe: msg.senderId == me?.id);
                        },
                      ),
              ),
              _Composer(controller: _ctrl, onSend: _send),
            ],
          );
        },
      ),
    );
  }
}

// ── Bubble ────────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? TddColors.text : TddColors.surface,
                border: isMe
                    ? null
                    : Border.all(color: TddColors.border, width: 0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 3),
                  bottomRight: Radius.circular(isMe ? 3 : 14),
                ),
              ),
              child: Text(
                message.content,
                style: TddTypography.sans(
                  size: 14,
                  color: isMe ? TddColors.bg : TddColors.text,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: TddTypography.mono(size: 9.5, color: TddColors.text4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Composer ──────────────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TddColors.bg,
        border: Border(top: BorderSide(color: TddColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
                style: TddTypography.sans(size: 14),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje…',
                  hintStyle:
                      TddTypography.sans(size: 14, color: TddColors.text4),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward,
                  size: 20, color: TddColors.accent),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
