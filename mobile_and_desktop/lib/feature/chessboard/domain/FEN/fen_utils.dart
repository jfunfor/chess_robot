// lib/feature/chessboard/domain/fen_utils.dart

import 'package:chess316/feature/chessboard/domain/models/chess_piece_enum.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_pieces.dart';

class FenUtils {
  /// Convert FEN string to board matrix
  static List<List<ChessPiece?>> fenToBoard(String fen) {
    List<List<ChessPiece?>> board =
        List.generate(8, (index) => List.generate(8, (index) => null));

    // Split FEN string, take first part (board state)
    final fenParts = fen.split(' ');
    final fenBoard = fenParts[0];
    final ranks = fenBoard.split('/');

    // Parse by row
    for (int row = 0; row < 8; row++) {
      int col = 0;
      for (int i = 0; i < ranks[row].length; i++) {
        final char = ranks[row][i];

        // Number represents consecutive empty squares
        if (int.tryParse(char) != null) {
          col += int.parse(char);
        } else {
          // Otherwise it's a piece
          board[row][col] = _fenCharToPiece(char);
          col++;
        }
      }
    }

    return board;
  }

  /// Convert board matrix to FEN string
  static String boardToFen(List<List<ChessPiece?>> board,
      {bool isWhiteTurn = true}) {
    String fen = '';

    // Process board positions
    for (int row = 0; row < 8; row++) {
      int emptyCount = 0;

      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];

        if (piece == null) {
          emptyCount++;
        } else {
          // If there were empty squares before, add the count
          if (emptyCount > 0) {
            fen += emptyCount.toString();
            emptyCount = 0;
          }

          // Add piece character
          fen += _pieceToFenChar(piece);
        }
      }

      // Handle end-of-row empty squares
      if (emptyCount > 0) {
        fen += emptyCount.toString();
      }

      // Add row separator (except for last row)
      if (row < 7) {
        fen += '/';
      }
    }

    // Add other FEN information
    fen += isWhiteTurn ? ' w ' : ' b ';
    fen += 'KQkq - 0 1'; // Simplified, just add basic info

    return fen;
  }

  /// Convert FEN character to piece object
  static ChessPiece? _fenCharToPiece(String char) {
    final isWhite = char.toUpperCase() == char;
    final pieceChar = char.toUpperCase();

    switch (pieceChar) {
      case 'P':
        return Pawn(isWhite: isWhite);
      case 'R':
        return Rook(isWhite: isWhite);
      case 'N':
        return Knight(isWhite: isWhite);
      case 'B':
        return Bishop(isWhite: isWhite);
      case 'Q':
        return Queen(isWhite: isWhite);
      case 'K':
        return King(isWhite: isWhite);
      default:
        return null;
    }
  }

  /// Convert piece object to FEN character
  static String _pieceToFenChar(ChessPiece piece) {
    String char = '';

    switch (piece.type) {
      case ChessPieceType.pawn:
        char = 'P';
        break;
      case ChessPieceType.rook:
        char = 'R';
        break;
      case ChessPieceType.knight:
        char = 'N';
        break;
      case ChessPieceType.bishop:
        char = 'B';
        break;
      case ChessPieceType.queen:
        char = 'Q';
        break;
      case ChessPieceType.king:
        char = 'K';
        break;
    }

    return piece.isWhite ? char : char.toLowerCase();
  }

  /// Get current turn from FEN
  static bool getIsWhiteTurn(String fen) {
    final parts = fen.split(' ');
    if (parts.length > 1) {
      return parts[1] == 'w';
    }
    return true; // Default to white's turn
  }

  /// Convert board coordinates to algebraic notation (e.g., "e4")
  static String positionToAlgebraic(int row, int col) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = 8 - row;
    return '$file$rank';
  }

  /// Convert algebraic notation to board coordinates (e.g., "e4" -> [4, 4])
  static List<int> algebraicToPosition(String algebraic) {
    final file = algebraic[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = 8 - int.parse(algebraic[1]);
    return [rank, file];
  }
}
