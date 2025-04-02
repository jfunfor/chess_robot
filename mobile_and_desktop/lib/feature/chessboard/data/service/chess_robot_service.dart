import 'package:chess316/core/constants/app_constants.dart';

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
  void _messageReceived(String data) {}

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
