import 'dart:developer';

import 'package:chess316/feature/chessboard/data/services/validate_moves.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece.dart';
import 'package:chess316/feature/chessboard/presentation/view_models/chess_board_view_model.dart';
import 'package:chess316/feature/chessboard/presentation/widgets/chess_field.dart';
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
  late List<List<ChessPiece?>> chessBoard;
  late final CalculateValidMoves movesModel;

  bool isFieldFilled(int index) {
    int x = index ~/ 8;
    int y = index % 8;
    bool isFilled = (x + y) % 2 == 0;
    return isFilled;
  }

  // ChessPiece? getPiece(int index) {
  //   chessBoard = widget.model.chessBoard;
  //   return chessBoard[index ~/ 8][index % 8];
  // }
  // ChessPiece? getPiece(int index) {
  //   return widget.model.chessBoard[index ~/ 8][index % 8];
  // }

  ChessPiece? getPiece(int index) {
    if (widget.model.chessBoard.isNotEmpty) {
      return widget.model.chessBoard[index ~/ 8][index % 8];
    }
    return null;
  }

  @override
  void initState() {
    widget.model.initChessBoard();
    movesModel = CalculateValidMoves();
    chessBoard = widget.model.chessBoard;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      body: Center(
        child: GridView.builder(
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
                    isSelected: widget.model.selectedFieldIndex == index,
                    onTap: () {
                      widget.model.selectPiece(index);
                    },
                    isValidMove: widget.model.validMoves[index],
                  );
                });
          },
        ),
      ),
    );
  }
}
