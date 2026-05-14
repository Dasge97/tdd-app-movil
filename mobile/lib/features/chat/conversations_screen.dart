import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/chat_conversation.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _conversationsProvider =
    FutureProvider<List<ChatConversation>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.conversations);
  final list = (resp.data['data'] as List? ?? resp.data as List);
  return list
      .map((e) =>
          ChatConversation.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_conversationsProvider),
        ),
        data: (conversations) => conversations.isEmpty
            ? const Center(child: Text('Sin conversaciones'))
            : ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (_, i) {
                  final conv = conversations[i];
                  final other = conv.otherUser;
                  return ListTile(
                    leading: Stack(
                      children: [
                        Avatar(
                          username: other.username,
                          avatarUrl: other.avatarUrl,
                          radius: 24,
                        ),
                        if (conv.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4FC3F7),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${conv.unreadCount}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(other.username,
                        style: TextStyle(
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.normal)),
                    subtitle: conv.lastMessage != null
                        ? Text(
                            conv.lastMessage!.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: conv.unreadCount > 0
                                    ? Colors.white70
                                    : Colors.white38),
                          )
                        : null,
                    trailing: conv.lastMessage != null
                        ? Text(
                            timeago.format(
                                conv.lastMessage!.createdAt,
                                locale: 'es'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          )
                        : null,
                    onTap: () =>
                        context.push('/home/chat/${conv.id}'),
                  );
                },
              ),
      ),
    );
  }
}
