import 'dart:developer';

import 'package:chess316/core/constants/app_constants.dart';
import 'package:tcp_socket_connection/tcp_socket_connection.dart';

class ChessRobotService {
  ChessRobotService() {
    startConnection();
  }

  static const _ip = AppConstants.robotIp;
  static const _port = AppConstants.robotPort;

  bool get isConnected => _tcpSocketConnection.isConnected();

  void checkConnection() {
    log(isConnected.toString());
    if (!isConnected) {
      throw "No connection to robot";
    }
  }

  final TcpSocketConnection _tcpSocketConnection =
      TcpSocketConnection(_ip, _port);

  Future<void> startConnection() async {
    _tcpSocketConnection.enableConsolePrint(true);
    await _tcpSocketConnection.connect(15000, _messageReceived, attempts: 3);
  }

  void _messageReceived(String data) {}

  Future<void> moveChessPiece(
      int boardFrom, int positionFrom, int boardTo, int positionTo) async {
    final command = 'Move,$boardFrom,$positionFrom,$boardTo,$positionTo\r\n';
    _tcpSocketConnection.sendMessage(command);
  }
}
