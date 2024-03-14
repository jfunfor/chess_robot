import 'dart:developer';

import 'package:chess316/feature/chessboard/domain/models/chess_piece.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece_enum.dart';

class CalculateValidMoves {
  bool isInBoard(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  List<List<int>> calculateValidMoves(
      int row, int col, ChessPiece piece, List<List<ChessPiece?>> board) {
    List<List<int>> moves = [];
    int direction = (piece.isWhite) ? -1 : 1;
    switch (piece.type) {
      case ChessPieceType.pawn:
        if (isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          moves.add([row + direction, col]);
        }

        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (isInBoard(row + 2 * direction, col) &&
              board[row + 2 * direction][col] == null &&
              board[row + direction][col] == null) {
            moves.add([row + 2 * direction, col]);
          }
        }

        if (isInBoard(row + direction, col - 1) &&
            board[row + direction][col - 1] != null &&
            board[row + direction][col - 1]!.isWhite) {
          moves.add([row + direction, col - 1]);
        }

        if (isInBoard(row + direction, col + 1) &&
            board[row + direction][col + 1] != null &&
            !board[row + direction][col + 1]!.isWhite) {
          moves.add([row + direction, col + 1]);
        }

      case ChessPieceType.king:
        final dirs = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1],
        ];
        for (var dir in dirs) {
          bool a = true;
          while (a) {
            var newRow = row + dir[0];
            var newCol = col + dir[1];
            if (!isInBoard(newRow, newCol)) {
              a = false;
            }
            final obstacle = board[newRow][newCol];
            if (obstacle != null) {
              if (obstacle.isWhite != piece.isWhite) {
                moves.add([newRow, newCol]);
              }
              a = false;
            }
            moves.add([newRow, newCol]);
          }
        }
      case ChessPieceType.queen:
        final dirs = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1],
        ];
        for (var dir in dirs) {
          var i = 1;
          while (true) {
            var newRow = row + i * dir[0];
            var newCol = col + i * dir[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            final obstacle = board[newRow][newCol];
            if (obstacle != null) {
              if (obstacle.isWhite != piece.isWhite) {
                moves.add([newRow, newCol]);
              }
              break;
            }
            moves.add([newRow, newCol]);
            i++;
          }
        }
      case ChessPieceType.rook:
        final directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ];
        for (var dir in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * dir[0];
            var newCol = col + i * dir[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            final obstacle = board[newRow][newCol];
            if (obstacle != null) {
              if (obstacle.isWhite != piece.isWhite) {
                moves.add([newRow, newCol]);
              }
              break;
            }
            moves.add([newRow, newCol]);
            i++;
          }
        }
      case ChessPieceType.bishop:
        final dirs = [
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1],
        ];
        for (var dir in dirs) {
          int i = 1;
          while (true) {
            int newRow = row + i * dir[0];
            int newCol = col + i * dir[1];

            if (!isInBoard(newRow, newCol)) {
              break;
            }
            final obstacle = board[newRow][newCol];
            if (obstacle != null) {
              if (obstacle.isWhite != piece.isWhite) {
                moves.add([newRow, newCol]);
              }
              break;
            }
            moves.add([newRow, newCol]);
            i++;
          }
        }
      case ChessPieceType.knight:
        final knightMoves = [
          [-2, -1],
          [-2, 1],
          [2, 1],
          [2, -1],
          [-1, -2],
          [-1, 2],
          [1, -2],
          [1, 2],
        ];
        for (var move in knightMoves) {
          int newRow = row + move[0];
          int newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) {
            continue;
          }
          final obstacle = board[newRow][newCol];
          if (obstacle != null) {
            if (obstacle.isWhite != piece.isWhite) {
              moves.add([newRow, newCol]);
            }
            continue;
          }
          moves.add([newRow, newCol]);
        }
    }
    return moves;
  }
}
