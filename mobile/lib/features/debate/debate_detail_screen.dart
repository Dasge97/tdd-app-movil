import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/comment.dart';
import '../../core/models/debate.dart';
import '../../shared/theme/app_theme.dart';
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
  final resp = await dio.get(ApiEndpoints.debateComments(debateId));
  final List list = resp.data is List
      ? resp.data as List
      : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
});

class DebateDetailScreen extends ConsumerStatefulWidget {
  final int debateId;
  const DebateDetailScreen({super.key, required this.debateId});

  @override
  ConsumerState<DebateDetailScreen> createState() =>
      _DebateDetailScreenState();
}

class _DebateDetailScreenState extends ConsumerState<DebateDetailScreen> {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(ApiEndpoints.debateComments(widget.debateId), data: {
        'content': text,
        if (_replyingTo != null) 'parentId': _replyingTo!.id,
      });
      _commentCtrl.clear();
      setState(() => _replyingTo = null);
      ref.invalidate(_commentsProvider(widget.debateId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _vote(Comment comment, String direction) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(ApiEndpoints.commentVote(comment.id),
          data: {'value': direction == 'up' ? 1 : -1});
      ref.invalidate(_commentsProvider(widget.debateId));
    } catch (_) {}
  }

  Future<String?> _showReportDialog(String title) {
    String? selected;
    const reasons = [
      'Desinformación o contenido falso',
      'Contenido ofensivo o discurso de odio',
      'Spam o publicidad',
      'Acoso o amenazas',
      'Otro',
    ];
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(
            title,
            style: TddTypography.serif(size: 17, weight: FontWeight.w500),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map(
                  (r) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r,
                        style: TddTypography.sans(size: 13)),
                    value: r,
                    groupValue: selected,
                    activeColor: TddColors.accent,
                    onChanged: (v) => setSt(() => selected = v),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TddTypography.mono(size: 11, color: TddColors.text3)),
            ),
            TextButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(ctx, selected),
              child: Text('Reportar',
                  style: TddTypography.mono(size: 11, color: TddColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportDebate() async {
    final reason = await _showReportDialog('Reportar debate');
    if (reason == null || !mounted) return;
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(ApiEndpoints.debateReport(widget.debateId),
          data: {'reason': reason});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Debate reportado. Lo revisaremos pronto.')),
        );
      }
    } catch (_) {}
  }

  Future<void> _reportComment(Comment comment) async {
    final reason = await _showReportDialog('Reportar comentario');
    if (reason == null || !mounted) return;
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(ApiEndpoints.commentReport(comment.id),
          data: {'reason': reason});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Comentario reportado. Lo revisaremos pronto.')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final debateAsync = ref.watch(_debateDetailProvider(widget.debateId));
    final commentsAsync = ref.watch(_commentsProvider(widget.debateId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: TddColors.text2),
        title: Text(
          'Debate',
          style: TddTypography.mono(size: 11, color: TddColors.text3),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: TddColors.text2),
            onSelected: (value) {
              if (value == 'report') _reportDebate();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'report',
                child: Text('Reportar debate',
                    style: TddTypography.sans(size: 14)),
              ),
            ],
          ),
        ],
      ),
      body: debateAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(_debateDetailProvider(widget.debateId)),
        ),
        data: (debate) {
          final user = debate.createdBy;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author row
                          Row(
                            children: [
                              Avatar(
                                username: user.username,
                                avatarUrl: user.avatarUrl,
                                size: 32,
                                isAiPersona: user.isAiPersona,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.username,
                                style: TddTypography.sans(
                                    size: 13, weight: FontWeight.w500),
                              ),
                              if (user.personaSpecialty != null) ...[
                                const SizedBox(width: 6),
                                Chip(label: Text(user.personaSpecialty!)),
                              ],
                              const Spacer(),
                              if (debate.publishedAt != null)
                                Text(
                                  timeago.format(debate.publishedAt!,
                                      locale: 'es'),
                                  style: TddTypography.mono(
                                      size: 10, color: TddColors.text4),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Title
                          Text(
                            debate.title,
                            style: TddTypography.serif(
                              size: 24,
                              weight: FontWeight.w500,
                              letterSpacing: -0.018,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Context
                          if (debate.context.length > 300)
                            _CollapsibleContext(text: debate.context)
                          else
                            Text(debate.context,
                                style: TddTypography.sans(
                                    size: 14, color: TddColors.text2,
                                    height: 1.6)),
                          // Source
                          if (debate.sourceUrl != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(debate.sourceUrl!)),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.open_in_new,
                                      size: 12, color: TddColors.text3),
                                  const SizedBox(width: 4),
                                  Text(
                                    debate.sourceName ?? 'Ver fuente',
                                    style: TddTypography.mono(
                                        size: 10, color: TddColors.text3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Position selector
                    const SizedBox(height: 20),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border.symmetric(
                          horizontal:
                              BorderSide(color: TddColors.border, width: 0.5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          _positionBtn('support', 'A favor', TddColors.favor),
                          _vDivider(),
                          _positionBtn('neutral', 'Neutral', TddColors.neutral),
                          _vDivider(),
                          _positionBtn('oppose', 'En contra', TddColors.contra),
                        ],
                      ),
                    ),
                    // Comments
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Text(
                        'Comentarios (${debate.commentCount ?? 0})',
                        style: TddTypography.mono(
                            size: 11, color: TddColors.text3),
                      ),
                    ),
                    commentsAsync.when(
                      loading: () => const LoadingIndicator(),
                      error: (e, _) => ErrorView(
                        message: e.toString(),
                        onRetry: () => ref
                            .invalidate(_commentsProvider(widget.debateId)),
                      ),
                      data: (comments) => comments.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Sé el primero en comentar.',
                                  style: TddTypography.sans(
                                      size: 14, color: TddColors.text3),
                                ),
                              ),
                            )
                          : Column(
                              children: comments
                                  .map((c) => CommentTile(
                                        comment: c,
                                        onReply: (c) =>
                                            setState(() => _replyingTo = c),
                                        onVote: _vote,
                                        onReport: _reportComment,
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              _CommentInput(
                controller: _commentCtrl,
                replyingTo: _replyingTo,
                onCancelReply: () => setState(() => _replyingTo = null),
                onSend: _sendComment,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _positionBtn(String value, String label, Color color) {
    final selected = _selectedPosition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setPosition(value),
        child: Column(
          children: [
            Text(
              selected ? '—' : '·',
              style: TddTypography.mono(
                size: 20,
                color: selected ? color : TddColors.text4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TddTypography.mono(
                size: 10,
                color: selected ? color : TddColors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 0.5,
        height: 40,
        color: TddColors.border,
      );
}

// ── Collapsible context ───────────────────────────────────────────────────────

class _CollapsibleContext extends StatefulWidget {
  final String text;
  const _CollapsibleContext({required this.text});

  @override
  State<_CollapsibleContext> createState() => _CollapsibleContextState();
}

class _CollapsibleContextState extends State<_CollapsibleContext> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: TddTypography.sans(
              size: 14, color: TddColors.text2, height: 1.6),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Ver menos' : 'Ver más',
            style: TddTypography.mono(size: 10, color: TddColors.text3),
          ),
        ),
      ],
    );
  }
}

// ── Composer ──────────────────────────────────────────────────────────────────

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
      decoration: const BoxDecoration(
        color: TddColors.bg,
        border: Border(top: BorderSide(color: TddColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      'Respondiendo a ${replyingTo!.user.username}',
                      style:
                          TddTypography.mono(size: 10, color: TddColors.accent),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: const Icon(Icons.close,
                          size: 14, color: TddColors.text3),
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
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: TddTypography.sans(size: 14),
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario…',
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
          ],
        ),
      ),
    );
  }
}
