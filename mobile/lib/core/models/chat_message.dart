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

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final int senderId;
    if (j['senderId'] is int) {
      senderId = j['senderId'] as int;
    } else if (j['sender'] is Map<String, dynamic>) {
      senderId = (j['sender'] as Map<String, dynamic>)['id'] as int;
    } else {
      senderId = 0;
    }
    return ChatMessage(
      id: (j['id'] as int?) ?? 0,
      conversationId: j['conversationId'] as int,
      senderId: senderId,
      content: j['content'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
    );
  }
}
