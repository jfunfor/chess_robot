import 'dart:developer';

import 'package:chess316/core/chess_icons/chess_icons.dart';
import 'package:chess316/feature/chessboard/data/services/validate_moves.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece_enum.dart';
import 'package:flutter/cupertino.dart';

class ChessBoardViewModel extends ChangeNotifier {
  List<List<ChessPiece?>> _chessBoard = [];
  List<bool> _selectedPieces = [];
  List<bool> _validMoves = [];
  int _selectedFieldRow = -1;
  int _selectedFieldColumn = -1;
  int _selectedFieldIndex = -1;

  int get selectedFieldIndex => _selectedFieldIndex;

  int get selectedFieldRow => _selectedFieldRow;

  int get selectedFieldColumn => _selectedFieldColumn;

  List<bool> get selectedPieces => _selectedPieces;

  List<List<ChessPiece?>> get chessBoard => _chessBoard;

  List<bool> get validMoves => _validMoves;

  ChessBoardViewModel() {
    initChessBoard();
  }

  void initChessBoard() {
    List<List<ChessPiece?>> initBoard = List.generate(
      8,
      (index) => List.generate(
        8,
        (index) => null,
      ),
    );
    List<bool> initSelectedPieces = List.generate(
      64,
      (index) => false,
    );

    List<bool> initValidMoves = List.generate(
      64,
      (index) => false,
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
        type: ChessPieceType.king, icon: ChessIcons.king, isWhite: false);
    initBoard[7][4] = ChessPiece(
        type: ChessPieceType.queen, icon: ChessIcons.queen, isWhite: true);
    initBoard[7][3] = ChessPiece(
        type: ChessPieceType.king, icon: ChessIcons.king, isWhite: true);

    _chessBoard = initBoard;
    _selectedPieces = initSelectedPieces;
    _validMoves = initValidMoves;
    notifyListeners();
  }

  void selectPiece(int index) {
    if (_selectedPieces[index]) {
      _selectedFieldIndex = -1;
      _selectedFieldRow = -1;
      _selectedFieldColumn = -1;
      _selectedPieces[index] = false;
      for (int i = 0; i < 64; i++) {
        _validMoves[i] = false;
      }
    } else {
      final row = index ~/ 8;
      final column = index % 8;

      if (_validMoves[index] == true &&
          _chessBoard[_selectedFieldRow][_selectedFieldColumn] != null) {
        movePiece(index);
      }

      if (_chessBoard[row][column] != null) {
        for (int i = 0; i < 64; i++) {
          _selectedPieces[i] = false;
          _validMoves[i] = false;
        }

        _selectedFieldIndex = index;
        _selectedFieldRow = index ~/ 8;
        _selectedFieldColumn = index % 8;
        _selectedPieces[index] = true;

        final ChessPiece piece =
            chessBoard[_selectedFieldRow][_selectedFieldColumn]!;

        final List<List<int>> moves = CalculateValidMoves().calculateValidMoves(
            _selectedFieldRow, _selectedFieldColumn, piece, chessBoard);

        for (var move in moves) {
          _validMoves[move[0] * 8 + move[1]] = true;
        }
      }
    }
    notifyListeners();
  }

  void movePiece(int index) {
    final row = index ~/ 8;
    final column = index % 8;
    _chessBoard[row][column] =
        _chessBoard[_selectedFieldRow][_selectedFieldColumn];
    _chessBoard[_selectedFieldRow][_selectedFieldColumn] = null;
  }
}
