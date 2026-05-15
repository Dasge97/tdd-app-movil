import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/chat_conversation.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _conversationsProvider =
    FutureProvider<List<ChatConversation>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.conversations);
  final List list = resp.data is List
      ? resp.data as List
      : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list
      .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_conversationsProvider);

    return Scaffold(
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_conversationsProvider),
        ),
        data: (conversations) => conversations.isEmpty
            ? Center(
                child: Text(
                  'Sin conversaciones.',
                  style: TddTypography.sans(size: 14, color: TddColors.text3),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: conversations.length,
                itemBuilder: (_, i) =>
                    _ConvRow(conv: conversations[i]),
              ),
      ),
    );
  }
}

class _ConvRow extends StatelessWidget {
  final ChatConversation conv;
  const _ConvRow({required this.conv});

  @override
  Widget build(BuildContext context) {
    final other = conv.otherUser;
    final hasUnread = conv.unreadCount > 0;

    return InkWell(
      onTap: () => context.push('/home/chat/${conv.id}'),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Avatar(
                  username: other.username,
                  avatarUrl: other.avatarUrl,
                  size: 44,
                  isAiPersona: other.isAiPersona,
                ),
                if (hasUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: TddColors.accent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${conv.unreadCount}',
                        style: TddTypography.mono(
                            size: 9, color: TddColors.accentInk),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        other.username,
                        style: TddTypography.sans(
                          size: 14,
                          weight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (conv.lastMessage != null)
                        Text(
                          timeago.format(conv.lastMessage!.createdAt,
                              locale: 'es'),
                          style: TddTypography.mono(
                              size: 10, color: TddColors.text4),
                        ),
                    ],
                  ),
                  if (conv.lastMessage != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      conv.lastMessage!.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TddTypography.sans(
                        size: 13,
                        color: hasUnread ? TddColors.text2 : TddColors.text3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
