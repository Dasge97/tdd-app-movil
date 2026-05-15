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

  bool _shouldReconnect = true;
  int _retryAttempt = 0;
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  Future<void> connect() async {
    _shouldReconnect = true;
    await _open();
  }

  Future<void> _open() async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse('${ApiEndpoints.wsUrl}?token=${token ?? ''}');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(data);
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
      _retryAttempt = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _retryAttempt = (_retryAttempt + 1).clamp(1, 6);
    final seconds = 1 << (_retryAttempt - 1); // 1, 2, 4, 8, 16, 32
    _reconnectTimer = Timer(Duration(seconds: seconds), _open);
  }

  void sendChatMessage(
    int conversationId,
    String content, {
    int? messageId,
    DateTime? createdAt,
  }) {
    _send({
      'type': 'chat',
      'conversationId': conversationId,
      'content': content,
      if (messageId != null) 'messageId': messageId,
      if (createdAt != null) 'createdAt': createdAt.toUtc().toIso8601String(),
    });
  }

  void ping() {
    _send({'type': 'ping'});
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

final wsClientProvider = Provider<WsClient>((ref) => WsClient());
