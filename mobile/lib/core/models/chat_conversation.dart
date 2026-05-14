import 'user.dart';
import 'chat_message.dart';

class ChatConversation {
  final int id;
  final String dmKey;
  final User otherUser;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.dmKey,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> j) =>
      ChatConversation(
        id: j['id'] as int,
        dmKey: j['dmKey'] as String,
        otherUser:
            User.fromJson(j['otherUser'] as Map<String, dynamic>),
        lastMessage: j['lastMessage'] != null
            ? ChatMessage.fromJson(
                j['lastMessage'] as Map<String, dynamic>)
            : null,
        unreadCount: (j['unreadCount'] as int?) ?? 0,
      );
}
