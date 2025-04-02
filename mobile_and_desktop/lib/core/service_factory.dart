// lib/core/service_factory.dart
import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';
import 'package:chess316/feature/chessboard/data/service/mock_chess_robot_service.dart'; // 如果有

ChessRobotService createChessRobotService({required bool useMock}) {
  if (useMock) {
    // 返回模拟服务实例
    return MockChessRobotService();
  } else {
    // 返回真实服务实例
    return ChessRobotService();
  }
}
