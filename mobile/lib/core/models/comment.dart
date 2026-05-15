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

  factory Comment.fromJson(Map<String, dynamic> j) {
    final userMap = j['user'] as Map<String, dynamic>;
    return Comment(
      id: j['id'] as int,
      debateId: j['debateId'] as int,
      userId: (j['userId'] as int?) ?? userMap['id'] as int,
      score: (j['score'] as int?) ?? 0,
      parentId: j['parentId'] as int?,
      content: j['content'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      user: User.fromJson(userMap),
      replies: (j['replies'] as List?)
              ?.map((r) => Comment.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
