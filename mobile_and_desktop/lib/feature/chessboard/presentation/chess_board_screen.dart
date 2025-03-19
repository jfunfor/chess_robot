import 'dart:math';

import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_pieces.dart';
import 'package:chess316/feature/chessboard/presentation/view_models/chess_board_view_model.dart';
import 'package:chess316/feature/chessboard/presentation/widgets/alert_dialog_content.dart';
import 'package:chess316/feature/chessboard/presentation/widgets/chess_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChessBoardPage extends StatelessWidget {
  final ChessRobotService robotService;

  const ChessBoardPage({super.key, required this.robotService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChessBoardViewModel(robotService: robotService),
      child:
          Consumer<ChessBoardViewModel>(builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chess Robot 316'),
            backgroundColor: Colors.brown[800],
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _showResetDialog(context, viewModel),
              )
            ],
          ),
          body: _buildChessBoard(viewModel),
        );
      }),
    );
  }

  Widget _buildChessBoard(ChessBoardViewModel viewModel) {
    return ChessBoardScreen(
      key: const Key('chessBoard'),
      model: viewModel,
    );
  }

  void _showResetDialog(BuildContext context, ChessBoardViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialogContent(
        onConfirmTap: () {
          viewModel.restartGame();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class ChessBoardScreen extends StatefulWidget {
  final ChessBoardViewModel model;

  const ChessBoardScreen({Key? key, required this.model}) : super(key: key);

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  bool isFieldFilled(int index) {
    int x = index ~/ 8;
    int y = index % 8;
    bool isFilled = (x + y) % 2 == 0;
    return isFilled;
  }

  ChessPiece? getPiece(int index) {
    if (widget.model.chessBoard.isNotEmpty) {
      return widget.model.chessBoard[index ~/ 8][index % 8];
    }
    return null;
  }

  void _updateUI() {
    if (mounted) setState(() {});
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
  void dispose() {
    // 仅移除监听，不处理model的dispose
    widget.model.removeListener(_updateUI);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChessBoardScreen oldWidget) {
    if (oldWidget.model != widget.model) {
      oldWidget.model.removeListener(_updateUI);
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
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      body: Center(
        child: LayoutBuilder(builder: (context, constraints) {
          return Container(
            constraints: BoxConstraints(
              maxWidth: min(600, constraints.maxHeight - 220),
            ),
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
              ],
            ),
          );
        }),
      ),
    );
  }
}

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
