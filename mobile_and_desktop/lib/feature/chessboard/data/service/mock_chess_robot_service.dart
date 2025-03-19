// lib/feature/chessboard/data/service/mock_chess_robot_service.dart
import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';

class MockChessRobotService implements ChessRobotService {
  final List<String> commandHistory = [];
  bool _simulateConnection = true;

  @override
  bool get isConnected => _simulateConnection;

  @override
  void startConnection() {
    // 禁用实际连接逻辑
  }

  @override
  Future<void> moveChessPiece(
      int boardFrom, int positionFrom, int boardTo, int positionTo) async {
    final command =
        _formatCommand(boardFrom, positionFrom, boardTo, positionTo);
    commandHistory.add(command);

    // 模拟2秒机器人操作延迟
    await Future.delayed(const Duration(seconds: 2));

    // 模拟成功响应
    return;
  }

  String _formatCommand(int bf, int pf, int bt, int pt) {
    return 'Move,$bf,$pf,$bt,$pt';
  }

  @override
  void checkConnection() {
    if (!_simulateConnection) {
      throw "Mock connection error";
    }
  }

  // 测试辅助方法
  void setConnectionState(bool connected) => _simulateConnection = connected;
}
