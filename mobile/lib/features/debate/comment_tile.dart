import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/models/comment.dart';
import '../../shared/widgets/avatar.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final void Function(Comment)? onReply;
  final void Function(Comment, String)? onVote;
  final bool isReply;

  const CommentTile({
    super.key,
    required this.comment,
    this.onReply,
    this.onVote,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(
                      username: comment.user.username,
                      avatarUrl: comment.user.avatarUrl,
                      radius: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.user.username,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                              fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt,
                          locale: 'es'),
                      style:
                          Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.thumb_up_outlined),
                      onPressed: () =>
                          onVote?.call(comment, 'up'),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${comment.score}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon:
                          const Icon(Icons.thumb_down_outlined),
                      onPressed: () =>
                          onVote?.call(comment, 'down'),
                    ),
                    const SizedBox(width: 12),
                    if (!isReply)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => onReply?.call(comment),
                        child: const Text('Responder',
                            style: TextStyle(
                                color: Color(0xFF4FC3F7),
                                fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
              (r) => CommentTile(
                comment: r,
                onVote: onVote,
                isReply: true,
              ),
            ),
        ],
      ),
    );
  }
}
