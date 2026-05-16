import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/models/comment.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/theme/app_theme.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final void Function(Comment)? onReply;
  final void Function(Comment, String)? onVote;
  final void Function(Comment)? onReport;
  final bool isReply;

  const CommentTile({
    super.key,
    required this.comment,
    this.onReply,
    this.onVote,
    this.onReport,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile(context);

    if (isReply) {
      return Stack(
        children: [
          Positioned(
            left: 16 + 15 - 0.5, // horizontal padding + half avatar width
            top: 0,
            bottom: 0,
            width: 1,
            child: ColoredBox(color: TddColors.border),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: tile,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile,
        if (comment.replies.isNotEmpty)
          ...comment.replies.map(
            (r) => CommentTile(comment: r, onVote: onVote, isReply: true),
          ),
        const Divider(),
      ],
    );
  }

  Widget _buildTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(
            username: comment.user.username,
            avatarUrl: comment.user.avatarUrl,
            size: 30,
            isAiPersona: comment.user.isAiPersona,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user.username,
                      style: TddTypography.sans(
                        size: 13,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${timeago.format(comment.createdAt, locale: 'es')}',
                      style: TddTypography.mono(
                        size: 10.5,
                        color: TddColors.text3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TddTypography.sans(size: 14),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onVote?.call(comment, 'up'),
                      child: Text(
                        '▲',
                        style: TddTypography.mono(
                          size: 11,
                          color: TddColors.text3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${comment.score}',
                      style: TddTypography.mono(
                        size: 12,
                        color: TddColors.text2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onVote?.call(comment, 'down'),
                      child: Text(
                        '▼',
                        style: TddTypography.mono(
                          size: 11,
                          color: TddColors.text3,
                        ),
                      ),
                    ),
                    if (!isReply) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => onReply?.call(comment),
                        child: Text(
                          'Responder',
                          style: TddTypography.mono(
                            size: 10.5,
                            color: TddColors.text3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => onReport?.call(comment),
                        child: Text(
                          'Reportar',
                          style: TddTypography.mono(
                            size: 10.5,
                            color: TddColors.text4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
