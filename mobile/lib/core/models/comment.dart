import 'user.dart';

class Comment {
  final int id;
  final int debateId;
  final int userId;
  final int score;
  final int? parentId;
  final String content;
  final DateTime createdAt;
  final User user;
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.debateId,
    required this.userId,
    required this.score,
    this.parentId,
    required this.content,
    required this.createdAt,
    required this.user,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] as int,
        debateId: j['debate_id'] as int,
        userId: j['user_id'] as int,
        score: (j['score'] as int?) ?? 0,
        parentId: j['parent_id'] as int?,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        user: User.fromJson(j['user'] as Map<String, dynamic>),
        replies: (j['replies'] as List?)
                ?.map((r) => Comment.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
