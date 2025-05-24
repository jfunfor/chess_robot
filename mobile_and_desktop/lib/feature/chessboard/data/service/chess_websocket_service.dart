// lib/feature/chessboard/data/service/chess_websocket_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class ChessWebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _channel != null;

  /// Connect to WebSocket server
  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen((dynamic message) {
        final Map<String, dynamic> parsedMessage = jsonDecode(message);
        _messageController.add(parsedMessage);
      }, onDone: () {
        _channel = null;
      }, onError: (error) {
        _messageController.addError(error);
        _channel = null;
      });
    } catch (e) {
      _messageController.addError(e);
      _channel = null;
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  /// Send move piece message
  void makeMove(String posStart, String posEnd) {
    if (_channel == null) return;

    final message = {
      'type': 'make_move',
      'data': {'pos_start': posStart, 'pos_end': posEnd}
    };

    _channel!.sink.add(jsonEncode(message));
  }

  /// Request board state
  void getBoardState() {
    if (_channel == null) return;

    final message = {'type': 'get_board_state'};

    _channel!.sink.add(jsonEncode(message));
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
