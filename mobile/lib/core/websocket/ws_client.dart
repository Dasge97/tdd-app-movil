import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_endpoints.dart';
import '../auth/token_storage.dart';

class WsClient {
  WebSocketChannel? _channel;
  final _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  final _storage = TokenStorage();

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  Future<void> connect() async {
    final token = await _storage.getAccessToken();
    final uri =
        Uri.parse('${ApiEndpoints.wsUrl}?token=${token ?? ''}');
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (raw) {
        try {
          final data =
              jsonDecode(raw as String) as Map<String, dynamic>;
          _controller.add(data);
        } catch (_) {}
      },
      onDone: () {},
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void sendChatMessage(int conversationId, String content) {
    _send({
      'type': 'chat',
      'conversationId': conversationId,
      'content': content,
    });
  }

  void ping() {
    _send({'type': 'ping'});
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}

final wsClientProvider = Provider<WsClient>((ref) => WsClient());
