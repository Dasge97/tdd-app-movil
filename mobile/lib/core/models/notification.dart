class AppNotification {
  final int id;
  final int? userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) =>
      AppNotification(
        id: j['id'] as int,
        userId: j['userId'] as int?,
        type: j['type'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        isRead: (j['isRead'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        data: j['data'] as Map<String, dynamic>?,
      );
}
