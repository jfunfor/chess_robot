import 'package:chess316/core/service_factory.dart';
import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';
import 'package:chess316/feature/chessboard_v2/presentation/view/chess_board_page.dart';
import 'package:chess316/feature/chessboard_v2/presentation/view_models/chess_board_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Global list to store interactions
List<String> backendLogs = [];
// Global controller for the log list
final ValueNotifier<List<String>> logsNotifier =
    ValueNotifier<List<String>>([]);

// Simple function to log backend interactions
void logBackend(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  final logEntry = "[$timestamp] $message";

  print(logEntry); // Console output
  backendLogs.add(logEntry);
  if (backendLogs.length > 100)
    backendLogs.removeAt(0); // Keep log size manageable
  logsNotifier.value = List.from(backendLogs);
}

void main() {
  const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  // Set useV2 default to true to always use V2 chessboard
  const useV2 = bool.fromEnvironment('USE_V2', defaultValue: true);

  // Create the robot service
  final ChessRobotService robotService =
      createChessRobotService(useMock: useMock);

  runApp(MyApp(
    robotService: robotService,
    useV2: useV2,
  ));
}

class MyApp extends StatelessWidget {
  final ChessRobotService robotService;
  final bool useV2;

  const MyApp({super.key, required this.robotService, this.useV2 = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Robot 316',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.blueGrey[100],
      ),
      home: Stack(
        children: [
          _buildHomeScreen(robotService, useV2),
          // Simple floating log viewer
          const Positioned(
            right: 10,
            bottom: 10,
            child: FloatingLogViewer(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(ChessRobotService robotService, bool useV2) {
    if (useV2) {
      // Use new version of the chessboard with logging
      return ChangeNotifierProvider(
        create: (_) => ChessBoardViewModel(onBackendLog: logBackend),
        child: ChessBoardPageV2(robotService: robotService),
      );
    } else {
      // Use original chessboard
      return ChessBoardPageV2(robotService: robotService);
    }
  }
}

// Simple floating button that expands to show logs
class FloatingLogViewer extends StatefulWidget {
  const FloatingLogViewer({Key? key}) : super(key: key);

  @override
  State<FloatingLogViewer> createState() => _FloatingLogViewerState();
}

class _FloatingLogViewerState extends State<FloatingLogViewer> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _expanded
        ? Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  color: Colors.blueGrey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Backend Interactions',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () {
                              backendLogs.clear();
                              logsNotifier.value = [];
                            },
                            tooltip: 'Clear logs',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _expanded = false),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: logsNotifier,
                    builder: (context, logs, _) {
                      return ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[logs.length - 1 - index];

                          // Green for received, blue for sent
                          Color textColor = log.contains('→')
                              ? Colors.blue[700]!
                              : Colors.green[700]!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        : FloatingActionButton(
            mini: true,
            child: const Icon(Icons.analytics),
            onPressed: () => setState(() => _expanded = true),
            tooltip: 'Show backend logs',
          );
  }
}
