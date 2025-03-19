import 'package:chess316/core/constants/app_constants.dart';
import 'package:dio/dio.dart';

import 'tcp_connection.dart';

class ChessRobotService {
  // Determine whether to use mock based on environment
  final bool _useMock;

  // TCP connection instance (used only in non-mock mode)
  TcpSocketConnection? _tcpSocketConnection;

  // HTTP client (used only in mock mode)
  Dio? _httpClient;

  static const _ip = AppConstants.robotIp;
  static const _port = AppConstants.robotPort;

  // Mock server URL
  static const _mockBaseUrl = 'http://localhost:3001';

  ChessRobotService({bool useMock = false}) : _useMock = useMock {
    if (_useMock) {
      _initMockConnection();
    } else {
      _initRealConnection();
    }
  }

  // Initialize mock connection
  void _initMockConnection() {
    print('Initializing mock robot connection');
    _httpClient = Dio(BaseOptions(
      baseUrl: _mockBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
  }

  // Initialize real TCP connection
  void _initRealConnection() {
    print('Initializing real robot connection');
    _tcpSocketConnection = TcpSocketConnection(_ip, _port);
    startConnection();
  }

  bool get isConnected {
    if (_useMock) {
      // In mock mode, always assume connected unless explicitly detected error
      return _httpClient != null;
    } else {
      return _tcpSocketConnection?.isConnected() ?? false;
    }
  }

  void checkConnection() {
    if (!isConnected) {
      throw "No connection to robot";
    }
  }

  /// Start connection - attempt to connect to server 10 times
  void startConnection() async {
    if (_useMock) return; // No need to start connection in mock mode

    _tcpSocketConnection?.enableConsolePrint(true);
    if (await _tcpSocketConnection?.canConnect(5000, attempts: 10) ?? false) {
      await _tcpSocketConnection?.connect(5000, _messageReceived, attempts: 10);
    }
  }

  /// Callback function for receiving server messages
  void _messageReceived(String data) {
    // Can add logging here
    print('Received robot message: $data');
  }

  /// Send command to move chess piece
  Future<void> moveChessPiece(
      int boardFrom, int positionFrom, int boardTo, int positionTo) async {
    if (_useMock) {
      await _mockMoveChessPiece(boardFrom, positionFrom, boardTo, positionTo);
    } else {
      await _realMoveChessPiece(boardFrom, positionFrom, boardTo, positionTo);
    }
  }

  /// Simulate moving chess piece using HTTP API
  Future<void> _mockMoveChessPiece(
      int boardFrom, int positionFrom, int boardTo, int positionTo) async {
    try {
      print(
          '[Mock] Sending move command: $boardFrom,$positionFrom → $boardTo,$positionTo');

      final response = await _httpClient?.post('/api/robot/move', data: {
        'boardFrom': boardFrom,
        'positionFrom': positionFrom,
        'boardTo': boardTo,
        'positionTo': positionTo
      });

      if (response?.statusCode != 200 || response?.data['success'] != true) {
        throw "Error occurred during sending command to mock server";
      }

      // Simulate delay for robot movement
      final delay = response?.data['estimatedTimeSeconds'] ?? 1;
      await Future.delayed(Duration(seconds: delay));
    } catch (e) {
      print('[Mock] Error: $e');
      throw "Error communicating with mock robot server: $e";
    }
  }

  /// Actually move chess piece using TCP connection
  Future<void> _realMoveChessPiece(
      int boardFrom, int positionFrom, int boardTo, int positionTo) async {
    final command = 'Move,$boardFrom,$positionFrom,$boardTo,$positionTo\r\n';
    final response = await _tcpSocketConnection?.sendMessage(command);
    if (response == null || !response.isNotEmpty) {
      throw "Error occurred during sending command :(";
    }
  }
}


/*import 'package:chess316/core/constants/app_constants.dart';
import 'tcp_connection.dart';

class ChessRobotService {
  ChessRobotService() {
    startConnection();
  }

  static const _ip = AppConstants.robotIp;
  static const _port = AppConstants.robotPort;

  bool get isConnected => _tcpSocketConnection.isConnected();

  void checkConnection() {
    if (!isConnected) {
      throw "No connection to robot";
    }
  }

  ///creates TCP connection to server
  final TcpSocketConnection _tcpSocketConnection =
      TcpSocketConnection(_ip, _port);

  /// starts connection by trying to connect to a server ten times
  void startConnection() async {
    _tcpSocketConnection.enableConsolePrint(true);
    if (await _tcpSocketConnection.canConnect(5000, attempts: 10)) {
      await _tcpSocketConnection.connect(5000, _messageReceived, attempts: 10);
    }
  }

  /// callback function for receiving messages from server
  /// never used, but needed in [_tcpSocketConnection.connect] method
  void _messageReceived(String data) {
  }

  ///sends message to server with valid command
  Future<void> moveChessPiece(
      int boardFrom, int positionFrom, int boardTo, int positionTo) async {
    final command = 'Move,$boardFrom,$positionFrom,$boardTo,$positionTo\r\n';
    final response = await _tcpSocketConnection.sendMessage(command);
    if (!response.isNotEmpty) {
      throw "Error occurred during sending command :(";
    }
  }
}
*/