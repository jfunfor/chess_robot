import 'dart:math';

import 'package:chess316/feature/chessboard/domain/models/chess_pieces.dart';
import 'package:chess316/feature/chessboard/presentation/view_models/chess_board_view_model.dart';
import 'package:chess316/feature/chessboard/presentation/widgets/alert_dialog_content.dart';
import 'package:chess316/feature/chessboard/presentation/widgets/chess_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChessBoardPage extends StatelessWidget {
  const ChessBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChessBoardScreen(model: ChessBoardViewModel());
  }
}

class ChessBoardScreen extends StatefulWidget {
  final ChessBoardViewModel model;

  const ChessBoardScreen({Key? key, required this.model}) : super(key: key);

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  // WebSocket connection controller
  final _serverUrlController = TextEditingController(
      text: 'ws://192.168.1.191:8765'); //Зависит от адреса бэкенда

  // Determine if a field should be filled (colored) based on its position
  bool isFieldFilled(int index) {
    int x = index ~/ 8;
    int y = index % 8;
    bool isFilled = (x + y) % 2 == 0;
    return isFilled;
  }

  // Get the chess piece at the given index
  ChessPiece? getPiece(int index) {
    if (widget.model.chessBoard.isNotEmpty) {
      return widget.model.chessBoard[index ~/ 8][index % 8];
    }
    return null;
  }

  @override
  void initState() {
    widget.model.addListener(() {
      if (widget.model.checkMate) {
        _showResetGameDialog(context, onConfirmTap: () {
          widget.model.restartGame();
          Navigator.of(context)
            ..pop()
            ..pop();
        });
      }
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ChessBoardScreen oldWidget) {
    oldWidget.model.dispose();
    widget.model.addListener(() {
      if (widget.model.checkMate) {
        _showResetGameDialog(context, onConfirmTap: () {
          widget.model.restartGame();
          Navigator.of(context)
            ..pop()
            ..pop();
        });
      }
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        title: const Text('Chess'),
        backgroundColor: Colors.brown[200],
      ),
      body: Center(
        child: LayoutBuilder(builder: (context, constraints) {
          return Container(
            constraints: BoxConstraints(
              maxWidth: min(600, constraints.maxHeight - 320),
            ),
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // WebSocket connection UI
                ListenableBuilder(
                    listenable: widget.model,
                    builder: (context, _) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _serverUrlController,
                                decoration: const InputDecoration(
                                  labelText: 'WebSocket Server Address',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: widget.model.isWebSocketConnected
                                  ? widget.model.disconnectWebSocket
                                  : () => widget.model.connectToWebSocket(
                                      _serverUrlController.text),
                              child: Text(widget.model.isWebSocketConnected
                                  ? 'Disconnect'
                                  : 'Connect'),
                            ),
                          ],
                        ),
                      );
                    }),

                // WebSocket status message
                ListenableBuilder(
                    listenable: widget.model,
                    builder: (context, _) {
                      if (widget.model.webSocketStatus.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            widget.model.webSocketStatus,
                            style: TextStyle(
                              color: widget.model.webSocketError
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                // Black's turn indicator
                ListenableBuilder(
                    listenable: widget.model,
                    builder: (context, _) {
                      return Text(
                        !widget.model.isWhiteTurn &&
                                widget.model.alertMessage.isEmpty
                            ? 'Black`s turn'
                            : !widget.model.isWhiteTurn
                                ? widget.model.alertMessage
                                : '',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    }),
                const SizedBox(
                  height: 20,
                ),
                // Chess board grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 64,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemBuilder: (context, index) {
                    return ListenableBuilder(
                        listenable: widget.model,
                        builder: (context, _) {
                          return ChessField(
                            isFilled: isFieldFilled(index),
                            piece: getPiece(index),
                            isSelected:
                                widget.model.selectedFieldIndex == index,
                            onTap: widget.model.isFieldEnabled
                                ? () {
                                    widget.model.selectPiece(index);
                                  }
                                : null,
                            isValidMove: widget.model.isFieldEnabled
                                ? widget.model.validMoves[index]
                                : false,
                          );
                        });
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                // White's turn indicator
                ListenableBuilder(
                    listenable: widget.model,
                    builder: (context, _) {
                      return Text(
                        widget.model.isWhiteTurn &&
                                widget.model.alertMessage.isEmpty
                            ? 'White`s turn'
                            : widget.model.isWhiteTurn
                                ? widget.model.alertMessage
                                : '',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    }),
                const SizedBox(height: 20),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reset game button
                    CupertinoButton(
                      onPressed: () {
                        _showResetGameDialog(context, onConfirmTap: () {
                          widget.model.restartGame();
                          Navigator.of(context).pop();
                        });
                      },
                      minSize: 0,
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Reset game?',
                        style: TextStyle(
                          color: Colors.brown,
                        ),
                      ),
                    ),

                    // Refresh board button (only shown when WebSocket is connected)
                    if (widget.model.isWebSocketConnected)
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: CupertinoButton(
                          onPressed: widget.model.refreshBoardState,
                          minSize: 0,
                          padding: EdgeInsets.zero,
                          child: const Text(
                            'Refresh board',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// Show reset game confirmation dialog
_showResetGameDialog(BuildContext context,
    {required VoidCallback onConfirmTap}) {
  showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) {
        return AlertDialogContent(
          onConfirmTap: onConfirmTap,
        );
      });
}
