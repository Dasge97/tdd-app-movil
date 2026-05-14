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
        dmKey: j['dm_key'] as String,
        otherUser:
            User.fromJson(j['other_user'] as Map<String, dynamic>),
        lastMessage: j['last_message'] != null
            ? ChatMessage.fromJson(
                j['last_message'] as Map<String, dynamic>)
            : null,
        unreadCount: (j['unread_count'] as int?) ?? 0,
      );
}
