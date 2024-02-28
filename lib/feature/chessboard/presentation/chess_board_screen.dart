import 'package:chess316/core/chess_icons/chess_icons.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece_enum.dart';
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

  const ChessBoardScreen({super.key, required this.model});

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late List<List<ChessPiece?>> chessBoard = [];

  bool isFilled(int index) {
    int x = index ~/ 8;
    int y = index % 8;
    bool isFilled = (x + y) % 2 == 0;
    return isFilled;
  }

  ChessPiece? getPiece(int index) {
    final int column = index % 8;
    final int row = index ~/ 8;
    return chessBoard[row][column];
  }

  void initStartBoard() {
    List<List<ChessPiece?>> initBoard = List.generate(
      8,
      (index) => List.generate(
        8,
        (index) => null,
      ),
    );

    for (int i = 0; i < 8; i++) {
      initBoard[1][i] = ChessPiece(
        type: ChessPieceType.pawn,
        icon: ChessIcons.pawn,
        isWhite: false,
      );
      initBoard[6][i] = ChessPiece(
        type: ChessPieceType.pawn,
        icon: ChessIcons.pawn,
        isWhite: true,
      );
    }

    initBoard[0][0] = ChessPiece(
        type: ChessPieceType.rook, icon: ChessIcons.rook, isWhite: false);
    initBoard[0][7] = ChessPiece(
        type: ChessPieceType.rook, icon: ChessIcons.rook, isWhite: false);
    initBoard[7][0] = ChessPiece(
        type: ChessPieceType.rook, icon: ChessIcons.rook, isWhite: true);
    initBoard[7][7] = ChessPiece(
        type: ChessPieceType.rook, icon: ChessIcons.rook, isWhite: true);

    initBoard[0][1] = ChessPiece(
        type: ChessPieceType.knight, icon: ChessIcons.knight, isWhite: false);
    initBoard[0][6] = ChessPiece(
        type: ChessPieceType.knight, icon: ChessIcons.knight, isWhite: false);
    initBoard[7][1] = ChessPiece(
        type: ChessPieceType.knight, icon: ChessIcons.knight, isWhite: true);
    initBoard[7][6] = ChessPiece(
        type: ChessPieceType.knight, icon: ChessIcons.knight, isWhite: true);

    initBoard[0][2] = ChessPiece(
        type: ChessPieceType.bishop, icon: ChessIcons.bishop, isWhite: false);
    initBoard[0][5] = ChessPiece(
        type: ChessPieceType.bishop, icon: ChessIcons.bishop, isWhite: false);
    initBoard[7][2] = ChessPiece(
        type: ChessPieceType.bishop, icon: ChessIcons.bishop, isWhite: true);
    initBoard[7][5] = ChessPiece(
        type: ChessPieceType.bishop, icon: ChessIcons.bishop, isWhite: true);

    initBoard[0][3] = ChessPiece(
        type: ChessPieceType.queen, icon: ChessIcons.queen, isWhite: false);
    initBoard[0][4] = ChessPiece(
        type: ChessPieceType.king, icon: ChessIcons.queen, isWhite: false);
    initBoard[7][4] = ChessPiece(
        type: ChessPieceType.queen, icon: ChessIcons.king, isWhite: true);
    initBoard[7][3] = ChessPiece(
        type: ChessPieceType.king, icon: ChessIcons.king, isWhite: true);

    chessBoard = initBoard;
  }

  @override
  void initState() {
    initStartBoard();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 64,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemBuilder: (context, index) {
            return ChessField(
              isFilled: isFilled(index),
              piece: getPiece(index),
              model: widget.model, //TODO: fix view model, so it can work with 64 fields not one
            );
          }),
    );
  }
}
