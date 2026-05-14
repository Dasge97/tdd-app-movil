import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/comment.dart';
import '../../core/models/debate.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'comment_tile.dart';

final _debateDetailProvider =
    FutureProvider.family<Debate, int>((ref, id) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.debateById(id));
  return Debate.fromJson(resp.data as Map<String, dynamic>);
});

final _commentsProvider =
    FutureProvider.family<List<Comment>, int>((ref, debateId) async {
  final dio = ref.read(apiClientProvider);
  final resp =
      await dio.get(ApiEndpoints.debateComments(debateId));
  final List list = resp.data is List ? resp.data as List : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list
      .map((e) => Comment.fromJson(e as Map<String, dynamic>))
      .toList();
});

class DebateDetailScreen extends ConsumerStatefulWidget {
  final int debateId;

  const DebateDetailScreen({super.key, required this.debateId});

  @override
  ConsumerState<DebateDetailScreen> createState() =>
      _DebateDetailScreenState();
}

class _DebateDetailScreenState
    extends ConsumerState<DebateDetailScreen> {
  String? _selectedPosition;
  final _commentCtrl = TextEditingController();
  Comment? _replyingTo;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _setPosition(String position) async {
    setState(() => _selectedPosition = position);
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(
        ApiEndpoints.debatePositions(widget.debateId),
        data: {'position': position},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(
        ApiEndpoints.debateComments(widget.debateId),
        data: {
          'content': text,
          if (_replyingTo != null)
            'parent_id': _replyingTo!.id,
        },
      );
      _commentCtrl.clear();
      setState(() => _replyingTo = null);
      ref.invalidate(_commentsProvider(widget.debateId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _vote(Comment comment, String direction) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(
        ApiEndpoints.commentVote(comment.id),
        data: {'direction': direction},
      );
      ref.invalidate(_commentsProvider(widget.debateId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final debateAsync =
        ref.watch(_debateDetailProvider(widget.debateId));
    final commentsAsync =
        ref.watch(_commentsProvider(widget.debateId));

    return Scaffold(
      appBar: AppBar(title: const Text('Debate')),
      body: debateAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref
              .invalidate(_debateDetailProvider(widget.debateId)),
        ),
        data: (debate) {
          final user = debate.createdBy;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Row(
                      children: [
                        Avatar(
                          username: user.username,
                          avatarUrl: user.avatarUrl,
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user.username,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.w600),
                                  ),
                                  if (user.personaSpecialty !=
                                      null) ...[
                                    const SizedBox(width: 6),
                                    Chip(
                                        label: Text(
                                            user.personaSpecialty!)),
                                  ],
                                ],
                              ),
                              if (debate.publishedAt != null)
                                Text(
                                  timeago.format(
                                      debate.publishedAt!,
                                      locale: 'es'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      debate.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    // Context
                    if (debate.context.length > 200)
                      ExpansionTile(
                        title: const Text('Ver contexto'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(debate.context,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium),
                          ),
                        ],
                      )
                    else
                      Text(debate.context,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium),
                    // Source link
                    if (debate.sourceUrl != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_new,
                            size: 14),
                        label: const Text('Ver fuente'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(debate.sourceUrl!)),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Position selector
                    Text(
                      'Tu posición',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _positionButton('support', 'A favor',
                            Icons.thumb_up_outlined),
                        const SizedBox(width: 8),
                        _positionButton('oppose', 'En contra',
                            Icons.thumb_down_outlined),
                        const SizedBox(width: 8),
                        _positionButton('neutral', 'Neutral',
                            Icons.remove_circle_outline),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Comments header
                    Text(
                      'Comentarios (${debate.commentCount ?? 0})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    commentsAsync.when(
                      loading: () => const LoadingIndicator(),
                      error: (e, _) => ErrorView(
                        message: e.toString(),
                        onRetry: () => ref.invalidate(
                            _commentsProvider(widget.debateId)),
                      ),
                      data: (comments) => comments.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: Text(
                                      'Sé el primero en comentar')),
                            )
                          : Column(
                              children: comments
                                  .map((c) => CommentTile(
                                        comment: c,
                                        onReply: (c) => setState(
                                            () => _replyingTo = c),
                                        onVote: _vote,
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              // Comment input
              _CommentInput(
                controller: _commentCtrl,
                replyingTo: _replyingTo,
                onCancelReply: () =>
                    setState(() => _replyingTo = null),
                onSend: _sendComment,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _positionButton(
      String value, String label, IconData icon) {
    final selected = _selectedPosition == value;
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon,
            size: 16,
            color: selected
                ? const Color(0xFF4FC3F7)
                : Colors.white54),
        label: Text(label,
            style: TextStyle(
              fontSize: 12,
              color: selected
                  ? const Color(0xFF4FC3F7)
                  : Colors.white54,
            )),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: selected
                ? const Color(0xFF4FC3F7)
                : Colors.white24,
            width: selected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 10),
        ),
        onPressed: () => _setPosition(value),
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final Comment? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  const _CommentInput({
    required this.controller,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                        'Respondiendo a ${replyingTo!.user.username}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4FC3F7))),
                    const Spacer(),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario...',
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
          ],
        ),
      ),
    );
  }
}
