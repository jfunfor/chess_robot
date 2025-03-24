import 'package:chess316/core/service_factory.dart';
import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';
import 'package:chess316/feature/chessboard/presentation/chess_board_screen.dart';
import 'package:flutter/material.dart';

void main() {
  const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

  runApp(MyApp(
    robotService: createChessRobotService(useMock: useMock),
  ));
}

class MyApp extends StatelessWidget {
  final ChessRobotService robotService;

  const MyApp({super.key, required this.robotService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Robot 316',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: ChessBoardPage(robotService: robotService), // key
    );
  }
}
