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
                            : widget.model.alertMessage,
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
                            onTap: () {
                              widget.model.selectPiece(index);
                            },
                            isValidMove: widget.model.validMoves[index],
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
                            : widget.model.alertMessage,
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
