class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as int,
        conversationId: j['conversationId'] as int,
        senderId: j['senderId'] as int,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
