import 'package:chess316/core/chess_icons/chess_icons.dart';

import 'chess_piece_enum.dart';

/// Represents all chess pieces with type, icon and color.
abstract class ChessPiece {
  final ChessPieceType type;
  final String icon;
  final bool isWhite;

  ChessPiece({required this.type, required this.icon, required this.isWhite});

  List<List<int>> validMoves(int row, int col, List<List<ChessPiece?>> board);
}

/// Checks if a given position is within the bounds of the chessboard.
bool _isInBoard(int row, int col) {
  return row >= 0 && row < 8 && col >= 0 && col < 8;
}

///Represents a pawn chess piece
///Overrides [validMoves] method according to rules of pawn moves
class Pawn extends ChessPiece {
  Pawn({
    ChessPieceType type = ChessPieceType.pawn,
    String icon = ChessIcons.pawn,
    bool isWhite = true,
  }) : super(type: type, icon: icon, isWhite: isWhite);

  @override
  List<List<int>> validMoves(int row, int col, List<List<ChessPiece?>> board) {
    List<List<int>> moves = [];
    int direction = (isWhite) ? -1 : 1;

    if (_isInBoard(row + direction, col) &&
        board[row + direction][col] == null) {
      moves.add([row + direction, col]);
    }

    if ((row == 1 && !isWhite) || (row == 6 && isWhite)) {
      if (_isInBoard(row + 2 * direction, col) &&
          board[row + 2 * direction][col] == null &&
          board[row + direction][col] == null) {
        moves.add([row + 2 * direction, col]);
      }
    }

    if (_isInBoard(row + direction, col - 1) &&
        board[row + direction][col - 1] != null &&
        board[row + direction][col - 1]!.isWhite != isWhite) {
      moves.add([row + direction, col - 1]);
    }

    if (_isInBoard(row + direction, col + 1) &&
        board[row + direction][col + 1] != null &&
        board[row + direction][col + 1]!.isWhite != isWhite) {
      moves.add([row + direction, col + 1]);
    }
    return moves;
  }
}

///Represents a king chess piece
///Overrides [validMoves] method according to rules of king moves
class King extends ChessPiece {
  King({
    ChessPieceType type = ChessPieceType.king,
    String icon = ChessIcons.king,
    bool isWhite = true,
  }) : super(type: type, icon: icon, isWhite: isWhite);

  @override
  List<List<int>> validMoves(int row, int col, List<List<ChessPiece?>> board) {
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
    List<List<int>> moves = [];
    for (var dir in dirs) {
      var newRow = row + dir[0];
      var newCol = col + dir[1];
      if (!_isInBoard(newRow, newCol)) {
        continue;
      }
      final obstacle = board[newRow][newCol];
      if (obstacle == null || obstacle.isWhite != isWhite) {
        moves.add([newRow, newCol]);
      }
    }
    return moves;
  }
}

///Represents a queen chess piece
///Overrides [validMoves] method according to rules of queen moves
class Queen extends ChessPiece {
  Queen({
    ChessPieceType type = ChessPieceType.queen,
    String icon = ChessIcons.queen,
    bool isWhite = true,
  }) : super(type: type, icon: icon, isWhite: isWhite);

  @override
  List<List<int>> validMoves(int row, int col, List<List<ChessPiece?>> board) {
    List<List<int>> moves = [];
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
        if (!_isInBoard(newRow, newCol)) {
          break;
        }
        final obstacle = board[newRow][newCol];
        if (obstacle != null) {
          if (obstacle.isWhite != isWhite) {
            moves.add([newRow, newCol]);
          }
          break;
        }
        moves.add([newRow, newCol]);
        i++;
      }
    }
    return moves;
  }
}

///Represents a knight chess piece
///Overrides [validMoves] method according to rules of knight moves
class Knight extends ChessPiece {
  Knight({
    ChessPieceType type = ChessPieceType.knight,
    String icon = ChessIcons.knight,
    bool isWhite = true,
  }) : super(type: type, icon: icon, isWhite: isWhite);

  @override
  List<List<int>> validMoves(int row, int col, List<List<ChessPiece?>> board) {
    List<List<int>> moves = [];

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
      if (!_isInBoard(newRow, newCol)) {
        continue;
      }
      final obstacle = board[newRow][newCol];
      if (obstacle != null) {
        if (obstacle.isWhite != isWhite) {
          moves.add([newRow, newCol]);
        }
        continue;
      }
      moves.add([newRow, newCol]);
    }
    return moves;
  }
}

///Represents a rook chess piece
///Overrides [validMoves] method according to rules of rook moves
class Rook extends ChessPiece {
  Rook({
    ChessPieceType type = ChessPieceType.rook,
    String icon = ChessIcons.rook,
    bool isWhite = true,
  }) : super(type: type, icon: icon, isWhite: isWhite);

  @override
  List<List<int>> validMoves(int row, int col, List<List<ChessPiece?>> board) {
    List<List<int>> moves = [];
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
        if (!_isInBoard(newRow, newCol)) {
          break;
        }
        final obstacle = board[newRow][newCol];
        if (obstacle != null) {
          if (obstacle.isWhite != isWhite) {
            moves.add([newRow, newCol]);
          }
          break;
        }
        moves.add([newRow, newCol]);
        i++;
      }
    }
    return moves;
  }
}

///Represents a pawn bishop piece
///Overrides [validMoves] method according to rules of bishop moves
class Bishop extends ChessPiece {
  Bishop({
    ChessPieceType type = ChessPieceType.bishop,
    String icon = ChessIcons.bishop,
    bool isWhite = true,
  }) : super(type: type, icon: icon, isWhite: isWhite);

  @override
  List<List<int>> validMoves(int row, int col, List<List<ChessPiece?>> board) {
    List<List<int>> moves = [];
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

        if (!_isInBoard(newRow, newCol)) {
          break;
        }
        final obstacle = board[newRow][newCol];
        if (obstacle != null) {
          if (obstacle.isWhite != isWhite) {
            moves.add([newRow, newCol]);
          }
          break;
        }
        moves.add([newRow, newCol]);
        i++;
      }
    }
    return moves;
  }
}
