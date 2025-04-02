// lib/core/service_factory.dart
// for mock
import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';

ChessRobotService createChessRobotService({required bool useMock}) {
  return ChessRobotService(useMock: useMock);
}
