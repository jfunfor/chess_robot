import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chess316/core/constants/app_constants.dart';

class ChessRobotSocketService {
  ChessRobotSocketService() {
    startConnection();
  }

  static const _ip = AppConstants.robotIp;
  static const _port = AppConstants.robotPort;

  bool get isConnected => _socket != null;

  void checkConnection() {
    if (!isConnected) {
      throw "No connection to robot";
    }
  }

  Socket? _socket;

  void startConnection() async {
    try {
      _socket = await Socket.connect(_ip, _port);
      _socket!.listen(
        _handleData,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );
      log('Connected to $_ip:$_port', name: 'Socket connection');
    } catch (e) {
      log('Error connecting to $_ip:$_port: $e');
    }
  }

  void _handleData(List<int> data) {}

  void _handleError(error) {
    log('Socket error: $error');
  }

  void _handleDone() {
    log('Socket closed');
  }

  Future<void> moveChessPiece(
      int boardFrom, int positionFrom, int boardTo, int positionTo) async {
    final command = 'Move,$boardFrom,$positionFrom,$boardTo,$positionTo\r\n';
    _socket!.add(ascii.encode(command));
  }
}
