// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
/*
import 'package:chess316/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
*/

import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';
import 'package:chess316/feature/chessboard/presentation/chess_board_screen.dart';
import 'package:chess316/feature/chessboard/presentation/widgets/chess_field.dart';
import 'package:chess316/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// 创建Mock服务
class MockChessRobotService extends Mock implements ChessRobotService {}

void main() {
  late MockChessRobotService mockService;

  setUp(() {
    mockService = MockChessRobotService();
    // 配置模拟方法
    when(() => mockService.checkConnection()).thenReturn(null);
  });

  testWidgets('Should render initial chess board', (WidgetTester tester) async {
    // 构建带mock服务的应用
    await tester.pumpWidget(MyApp(
      robotService: mockService,
    ));

    // 验证初始棋盘元素
    expect(find.byType(ChessBoardPage), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ChessField), findsNWidgets(64));
  });

  testWidgets('Should show reset dialog on app bar button tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      robotService: mockService,
    ));

    // 点击刷新按钮
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // 验证对话框弹出
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Confirm Reset'), findsOneWidget);
  });
}
