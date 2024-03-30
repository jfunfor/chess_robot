import 'package:chess316/feature/chessboard/domain/models/chess_pieces.dart';
import 'package:chess316/feature/chessboard/presentation/view_models/chess_board_view_model.dart';
import 'package:chess316/feature/chessboard/presentation/widgets/chess_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/styles/colors.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      body: Center(
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
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
                        widget.model.isWhiteTurn ? 'White`s turn' : ' ',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    }),
                const SizedBox(height: 20),
                if (widget.model.check)
                  _showResetGameDialog(context, onConfirmTap: () {
                    widget.model.restartGame();
                    Navigator.of(context).pop();
                  }),
                ListenableBuilder(
                    listenable: widget.model,
                    builder: (context, _) {
                      return Text(
                        'check: ${widget.model.check}',
                      );
                    }),
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
          ),
        ),
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
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20.0).copyWith(top: 40),
          backgroundColor: Colors.brown[100],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Play again?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(AppColors.darkBrown),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(AppColors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('No'),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  OutlinedButton(
                    onPressed: onConfirmTap,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(AppColors.darkBrown),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(AppColors.white),
                    ),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ],
          ),
        );
      });
}
