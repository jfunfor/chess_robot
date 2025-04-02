import 'package:chess316/feature/chessboard_v2/domain/models/chess_pieces.dart';

class FenParser {
  // Convert FEN string to board state
  static List<List<ChessPiece?>> fenToBoard(String fen) {
    List<List<ChessPiece?>> board =
        List.generate(8, (_) => List.generate(8, (_) => null));

    // Get the board part of FEN (first part)
    String boardPart = fen.split(' ')[0];
    List<String> rows = boardPart.split('/');

    for (int row = 0; row < 8; row++) {
      int col = 0;
      for (int j = 0; j < rows[row].length; j++) {
        String char = rows[row][j];

        // Numbers represent consecutive empty squares
        if (RegExp(r'[1-8]').hasMatch(char)) {
          col += int.parse(char);
        } else {
          // Piece symbols
          bool isWhite = char == char.toUpperCase();
          char = char.toLowerCase();

          ChessPiece? piece;
          switch (char) {
            case 'p':
              piece = Pawn(isWhite: isWhite);
              break;
            case 'r':
              piece = Rook(isWhite: isWhite);
              break;
            case 'n':
              piece = Knight(isWhite: isWhite);
              break;
            case 'b':
              piece = Bishop(isWhite: isWhite);
              break;
            case 'q':
              piece = Queen(isWhite: isWhite);
              break;
            case 'k':
              piece = King(isWhite: isWhite);
              break;
          }

          board[row][col] = piece;
          col++;
        }
      }
    }

    return board;
  }

  // Convert board state to FEN string
  static String boardToFen(List<List<ChessPiece?>> board, bool isWhiteTurn,
      {String castlingRights = 'KQkq',
      String enPassantTarget = '-',
      int halfMoveClock = 0,
      int fullMoveNumber = 1}) {
    StringBuffer fen = StringBuffer();

    // Build the board part
    for (int row = 0; row < 8; row++) {
      int emptyCount = 0;

      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];

        if (piece == null) {
          emptyCount++;
        } else {
          // If there are empty squares, record them first
          if (emptyCount > 0) {
            fen.write(emptyCount);
            emptyCount = 0;
          }

          // Add piece symbol
          String symbol = _getPieceSymbol(piece);
          fen.write(symbol);
        }
      }

      // Handle empty squares at end of row
      if (emptyCount > 0) {
        fen.write(emptyCount);
      }

      // Add row separator (except for the last row)
      if (row < 7) {
        fen.write('/');
      }
    }

    // Complete FEN string with all components
    fen.write(' ${isWhiteTurn ? 'w' : 'b'}');
    fen.write(' $castlingRights');
    fen.write(' $enPassantTarget');
    fen.write(' $halfMoveClock');
    fen.write(' $fullMoveNumber');

    return fen.toString();
  }

  // Get FEN symbol for a piece
  static String _getPieceSymbol(ChessPiece piece) {
    String symbol;

    if (piece is Pawn) {
      symbol = 'p';
    } else if (piece is Rook) {
      symbol = 'r';
    } else if (piece is Knight) {
      symbol = 'n';
    } else if (piece is Bishop) {
      symbol = 'b';
    } else if (piece is Queen) {
      symbol = 'q';
    } else if (piece is King) {
      symbol = 'k';
    } else {
      return '?';
    }

    return piece.isWhite ? symbol.toUpperCase() : symbol;
  }

  // Convert algebraic notation (e.g., "e4") to board coordinates
  static List<int> algebraicToCoords(String algebraic) {
    if (algebraic.length != 2) return [-1, -1];

    int col = algebraic.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int row = 8 - int.parse(algebraic[1]);

    return [row, col];
  }

  // Convert board coordinates to algebraic notation
  static String coordsToAlgebraic(int row, int col) {
    String file = String.fromCharCode('a'.codeUnitAt(0) + col);
    String rank = (8 - row).toString();
    return '$file$rank';
  }

  // Parse a complete FEN string into its components
  static Map<String, dynamic> parseFen(String fen) {
    List<String> parts = fen.split(' ');

    if (parts.length < 6) {
      // Handle incomplete FEN by adding default values
      if (parts.length == 2) {
        parts.add('KQkq'); // Default castling rights
        parts.add('-'); // Default en-passant target
        parts.add('0'); // Default half move clock
        parts.add('1'); // Default full move number
      } else {
        throw FormatException('Invalid FEN string format: $fen');
      }
    }

    return {
      'board': fenToBoard(fen),
      'isWhiteTurn': parts[1] == 'w',
      'castlingRights': parts[2],
      'enPassantTarget': parts[3],
      'halfMoveClock': int.parse(parts[4]),
      'fullMoveNumber': int.parse(parts[5]),
    };
  }

  // Check if a move is valid according to chess rules
  static bool isValidMove(List<List<ChessPiece?>> board, String startPos,
      String endPos, bool isWhiteTurn,
      {String castlingRights = 'KQkq', String? enPassantTarget}) {
    // Convert algebraic notation to coordinates
    List<int> startCoords = algebraicToCoords(startPos);
    List<int> endCoords = algebraicToCoords(endPos);

    int startRow = startCoords[0];
    int startCol = startCoords[1];
    int endRow = endCoords[0];
    int endCol = endCoords[1];

    // Check if coordinates are valid
    if (startRow < 0 ||
        startRow >= 8 ||
        startCol < 0 ||
        startCol >= 8 ||
        endRow < 0 ||
        endRow >= 8 ||
        endCol < 0 ||
        endCol >= 8) {
      return false;
    }

    // Get the piece at start position
    ChessPiece? piece = board[startRow][startCol];

    // Check if piece exists and belongs to current player
    if (piece == null || piece.isWhite != isWhiteTurn) {
      return false;
    }

    // Check if destination has own piece
    if (board[endRow][endCol]?.isWhite == isWhiteTurn) {
      return false;
    }

    // Special case: Castling
    if (piece is King && (startCol - endCol).abs() > 1) {
      return _isValidCastling(board, startRow, startCol, endRow, endCol,
          castlingRights, isWhiteTurn);
    }

    // Special case: En passant
    if (piece is Pawn && startCol != endCol && board[endRow][endCol] == null) {
      // Check if move matches en passant target
      if (enPassantTarget != null &&
          enPassantTarget != '-' &&
          coordsToAlgebraic(endRow, endCol) == enPassantTarget) {
        // Valid en passant capture
      } else {
        return false; // Invalid diagonal pawn move (no capture)
      }
    }

    // Get valid moves for the piece
    List<List<int>> validMoves = piece.validMoves(startRow, startCol, board);

    // Check if end position is in the list of valid moves
    bool isValid = false;
    for (List<int> move in validMoves) {
      if (move[0] == endRow && move[1] == endCol) {
        isValid = true;
        break;
      }
    }

    if (!isValid) return false;

    // Check if move would leave king in check
    if (moveWouldLeaveKingInCheck(
        board, piece, startRow, startCol, endRow, endCol)) {
      return false;
    }

    return true;
  }

  // Check if castling is valid
  static bool _isValidCastling(
      List<List<ChessPiece?>> board,
      int startRow,
      int startCol,
      int endRow,
      int endCol,
      String castlingRights,
      bool isWhiteTurn) {
    // Kingside castling
    if (endCol > startCol) {
      // Check castling rights
      if (isWhiteTurn && !castlingRights.contains('K')) return false;
      if (!isWhiteTurn && !castlingRights.contains('k')) return false;

      // Check if squares between king and rook are empty
      for (int c = startCol + 1; c < 7; c++) {
        if (board[startRow][c] != null) return false;
      }

      // Check if king is in check or would pass through check
      if (isInCheck(board, isWhiteTurn)) return false;
      if (squareIsAttacked(board, startRow, startCol + 1, !isWhiteTurn)) {
        return false;
      }
      if (squareIsAttacked(board, startRow, startCol + 2, !isWhiteTurn)) {
        return false;
      }
      // Check if rook is present
      ChessPiece? rook = board[startRow][7];
      if (rook == null || (rook is! Rook) || rook.isWhite != isWhiteTurn) {
        return false;
      }

      return true;
    }
    // Queenside castling
    else {
      // Check castling rights
      if (isWhiteTurn && !castlingRights.contains('Q')) return false;
      if (!isWhiteTurn && !castlingRights.contains('q')) return false;

      // Check if squares between king and rook are empty
      for (int c = startCol - 1; c > 0; c--) {
        if (board[startRow][c] != null) return false;
      }

      // Check if king is in check or would pass through check
      if (isInCheck(board, isWhiteTurn)) return false;
      if (squareIsAttacked(board, startRow, startCol - 1, !isWhiteTurn)) {
        return false;
      }
      if (squareIsAttacked(board, startRow, startCol - 2, !isWhiteTurn)) {
        return false;
      }

      // Check if rook is present
      ChessPiece? rook = board[startRow][0];
      if (rook == null || rook is! Rook || rook.isWhite != isWhiteTurn) {
        return false;
      }

      return true;
    }
  }

  // Check if a move would leave the king in check
  static bool moveWouldLeaveKingInCheck(List<List<ChessPiece?>> board,
      ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    // Create a deep copy of the board to prevent modifications to the original
    List<List<ChessPiece?>> tempBoard =
        List.generate(8, (r) => List.generate(8, (c) => board[r][c]?.copy()));

    // Make the move on the temporary board
    ChessPiece? movingPiece = tempBoard[startRow][startCol];
    tempBoard[endRow][endCol] = movingPiece;
    tempBoard[startRow][startCol] = null;

    // Special case: En passant capture
    if (movingPiece is Pawn &&
        startCol != endCol &&
        board[endRow][endCol] == null) {
      // Remove the captured pawn
      tempBoard[startRow][endCol] = null;
    }

    // Special case: Castling - move the rook too
    if (movingPiece is King && (startCol - endCol).abs() > 1) {
      int rookStartCol = endCol > startCol ? 7 : 0;
      int rookEndCol = endCol > startCol ? endCol - 1 : endCol + 1;

      ChessPiece? rook = tempBoard[startRow][rookStartCol];
      tempBoard[startRow][rookEndCol] = rook;
      tempBoard[startRow][rookStartCol] = null;
    }

    // Find the king
    int kingRow = -1, kingCol = -1;

    // If the moved piece is the king, use its new position
    if (movingPiece is King) {
      kingRow = endRow;
      kingCol = endCol;
    } else {
      // Otherwise find the king
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          ChessPiece? p = tempBoard[r][c];
          if (p != null && p is King && p.isWhite == piece.isWhite) {
            kingRow = r;
            kingCol = c;
            break;
          }
        }
        if (kingRow != -1) break;
      }
    }

    // Check if king is in check
    return squareIsAttacked(tempBoard, kingRow, kingCol, !piece.isWhite);
  }

  // Check if a square is attacked by any opponent piece (optimized)
  static bool squareIsAttacked(
      List<List<ChessPiece?>> board, int row, int col, bool byWhite) {
    // Check for pawn attacks
    int pawnRow = byWhite ? row + 1 : row - 1;
    if (pawnRow >= 0 && pawnRow < 8) {
      // Check left diagonal
      if (col - 1 >= 0) {
        ChessPiece? piece = board[pawnRow][col - 1];
        if (piece is Pawn && piece.isWhite == byWhite) {
          return true;
        }
      }
      // Check right diagonal
      if (col + 1 < 8) {
        ChessPiece? piece = board[pawnRow][col + 1];
        if (piece is Pawn && piece.isWhite == byWhite) {
          return true;
        }
      }
    }

    // Check for knight attacks
    final knightMoves = [
      [-2, -1],
      [-2, 1],
      [-1, -2],
      [-1, 2],
      [1, -2],
      [1, 2],
      [2, -1],
      [2, 1]
    ];

    for (var move in knightMoves) {
      int r = row + move[0];
      int c = col + move[1];

      if (r >= 0 && r < 8 && c >= 0 && c < 8) {
        ChessPiece? piece = board[r][c];
        if (piece is Knight && piece.isWhite == byWhite) {
          return true;
        }
      }
    }

    // Check for king attacks (one square in any direction)
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;

        int r = row + dr;
        int c = col + dc;

        if (r >= 0 && r < 8 && c >= 0 && c < 8) {
          ChessPiece? piece = board[r][c];
          if (piece is King && piece.isWhite == byWhite) {
            return true;
          }
        }
      }
    }

    // Check for rook/queen attacks along ranks and files
    final rookDirections = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ];
    for (var dir in rookDirections) {
      int r = row + dir[0];
      int c = col + dir[1];

      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        ChessPiece? piece = board[r][c];

        if (piece != null) {
          if (piece.isWhite == byWhite && (piece is Rook || piece is Queen)) {
            return true;
          }
          break; // Blocked by a piece
        }

        r += dir[0];
        c += dir[1];
      }
    }

    // Check for bishop/queen attacks along diagonals
    final bishopDirections = [
      [-1, -1],
      [-1, 1],
      [1, -1],
      [1, 1]
    ];
    for (var dir in bishopDirections) {
      int r = row + dir[0];
      int c = col + dir[1];

      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        ChessPiece? piece = board[r][c];

        if (piece != null) {
          if (piece.isWhite == byWhite && (piece is Bishop || piece is Queen)) {
            return true;
          }
          break; // Blocked by a piece
        }

        r += dir[0];
        c += dir[1];
      }
    }

    return false;
  }

  // Execute a move and update the board
  static Map<String, dynamic> executeMove(List<List<ChessPiece?>> board,
      String startPos, String endPos, bool isWhiteTurn,
      {String castlingRights = 'KQkq',
      String enPassantTarget = '-',
      int halfMoveClock = 0,
      int fullMoveNumber = 1,
      String? promotionPiece}) {
    List<int> startCoords = algebraicToCoords(startPos);
    List<int> endCoords = algebraicToCoords(endPos);

    int startRow = startCoords[0];
    int startCol = startCoords[1];
    int endRow = endCoords[0];
    int endCol = endCoords[1];

    ChessPiece? piece = board[startRow][startCol];
    if (piece == null) return {'board': board, 'isWhiteTurn': isWhiteTurn};

    // Create a copy of the board
    List<List<ChessPiece?>> newBoard =
        List.generate(8, (r) => List.generate(8, (c) => board[r][c]));

    // Get piece and prepare move
    piece = newBoard[startRow][startCol];

    // Update castling rights if king or rook moves
    String newCastlingRights = castlingRights;
    if (piece is King) {
      if (piece.isWhite) {
        newCastlingRights =
            newCastlingRights.replaceAll('K', '').replaceAll('Q', '');
      } else {
        newCastlingRights =
            newCastlingRights.replaceAll('k', '').replaceAll('q', '');
      }
    } else if (piece is Rook) {
      if (piece.isWhite) {
        if (startRow == 7 && startCol == 0) {
          newCastlingRights = newCastlingRights.replaceAll('Q', '');
        }
        if (startRow == 7 && startCol == 7) {
          newCastlingRights = newCastlingRights.replaceAll('K', '');
        }
      } else {
        if (startRow == 0 && startCol == 0) {
          newCastlingRights = newCastlingRights.replaceAll('q', '');
        }
        if (startRow == 0 && startCol == 7) {
          newCastlingRights = newCastlingRights.replaceAll('k', '');
        }
      }
    }
    if (newCastlingRights.isEmpty) newCastlingRights = '-';

    // Update half-move clock
    int newHalfMoveClock = halfMoveClock;
    if (piece is Pawn || newBoard[endRow][endCol] != null) {
      newHalfMoveClock = 0; // Reset on pawn move or capture
    } else {
      newHalfMoveClock++; // Increment otherwise
    }

    // Update full move number
    int newFullMoveNumber = fullMoveNumber;
    if (!isWhiteTurn) {
      newFullMoveNumber++; // Increment after Black's move
    }

    // Handle special moves

    // Castling
    String newEnPassantTarget = '-';
    if (piece is King && (startCol - endCol).abs() > 1) {
      // Move the king
      newBoard[endRow][endCol] = piece;
      newBoard[startRow][startCol] = null;

      // Move the rook
      int rookStartCol = endCol > startCol ? 7 : 0;
      int rookEndCol = endCol > startCol ? endCol - 1 : endCol + 1;

      ChessPiece? rook = newBoard[startRow][rookStartCol];
      newBoard[startRow][rookEndCol] = rook;
      newBoard[startRow][rookStartCol] = null;
    }
    // En passant capture
    else if (piece is Pawn &&
        startCol != endCol &&
        newBoard[endRow][endCol] == null) {
      // Move the pawn
      newBoard[endRow][endCol] = piece;
      newBoard[startRow][startCol] = null;

      // Remove the captured pawn
      newBoard[startRow][endCol] = null;
    }
    // Pawn double move (set en passant target)
    else if (piece is Pawn && (startRow - endRow).abs() == 2) {
      // Move the pawn
      newBoard[endRow][endCol] = piece;
      newBoard[startRow][startCol] = null;

      // Set en passant target square
      int enPassantRow = (startRow + endRow) ~/ 2;
      newEnPassantTarget = coordsToAlgebraic(enPassantRow, startCol);
    }
    // Pawn promotion
    else if (piece is Pawn && (endRow == 0 || endRow == 7)) {
      // Remove the pawn
      newBoard[startRow][startCol] = null;

      // Add the promotion piece
      ChessPiece? newPiece;
      if (promotionPiece == null || promotionPiece == 'queen') {
        newPiece = Queen(isWhite: piece.isWhite);
      } else if (promotionPiece == 'rook') {
        newPiece = Rook(isWhite: piece.isWhite);
      } else if (promotionPiece == 'bishop') {
        newPiece = Bishop(isWhite: piece.isWhite);
      } else if (promotionPiece == 'knight') {
        newPiece = Knight(isWhite: piece.isWhite);
      }

      newBoard[endRow][endCol] = newPiece;
    }
    // Regular move
    else {
      newBoard[endRow][endCol] = piece;
      newBoard[startRow][startCol] = null;
    }

    // Toggle turn
    bool newTurn = !isWhiteTurn;

    return {
      'board': newBoard,
      'isWhiteTurn': newTurn,
      'castlingRights': newCastlingRights,
      'enPassantTarget': newEnPassantTarget,
      'halfMoveClock': newHalfMoveClock,
      'fullMoveNumber': newFullMoveNumber
    };
  }

  // Check if a player is in check
  static bool isInCheck(List<List<ChessPiece?>> board, bool isWhiteKing) {
    // Find the king
    int kingRow = -1, kingCol = -1;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = board[r][c];
        if (piece != null && piece is King && piece.isWhite == isWhiteKing) {
          kingRow = r;
          kingCol = c;
          break;
        }
      }
      if (kingRow != -1) break;
    }

    if (kingRow == -1) return false; // No king found

    return squareIsAttacked(board, kingRow, kingCol, !isWhiteKing);
  }

  // Check if a player is in checkmate
  static bool isCheckmate(List<List<ChessPiece?>> board, bool isWhiteTurn) {
    // First check if the king is in check
    if (!isInCheck(board, isWhiteTurn)) return false;

    // Then check if any move can get the king out of check
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = board[r][c];
        if (piece != null && piece.isWhite == isWhiteTurn) {
          // Get all valid moves for this piece
          List<List<int>> moves = piece.validMoves(r, c, board);

          for (var move in moves) {
            int endRow = move[0];
            int endCol = move[1];

            // Check if this move would get the king out of check
            if (!moveWouldLeaveKingInCheck(
                board, piece, r, c, endRow, endCol)) {
              return false; // Found a legal move, not checkmate
            }
          }
        }
      }
    }

    // No legal moves and king is in check - checkmate
    return true;
  }

  // Check if the position is a stalemate
  static bool isStalemate(List<List<ChessPiece?>> board, bool isWhiteTurn) {
    // First check that the king is not in check
    if (isInCheck(board, isWhiteTurn)) return false;

    // Then check if any legal move exists
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = board[r][c];
        if (piece != null && piece.isWhite == isWhiteTurn) {
          // Get all valid moves for this piece
          List<List<int>> moves = piece.validMoves(r, c, board);

          for (var move in moves) {
            int endRow = move[0];
            int endCol = move[1];

            // Check if this move is legal
            if (!moveWouldLeaveKingInCheck(
                board, piece, r, c, endRow, endCol)) {
              return false; // Found a legal move, not stalemate
            }
          }
        }
      }
    }

    // No legal moves and king is not in check - stalemate
    return true;
  }

  // Check if the game is drawn by the 50-move rule
  static bool isFiftyMoveRule(int halfMoveClock) {
    return halfMoveClock >= 100; // 50 moves = 100 half-moves
  }

  // Check if the game is drawn by insufficient material
  static bool isInsufficientMaterial(List<List<ChessPiece?>> board) {
    int whiteBishops = 0;
    int blackBishops = 0;
    int whiteKnights = 0;
    int blackKnights = 0;
    bool hasWhiteQueenRookPawn = false;
    bool hasBlackQueenRookPawn = false;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = board[r][c];
        if (piece == null) continue;

        if (piece is Pawn || piece is Rook || piece is Queen) {
          if (piece.isWhite) {
            hasWhiteQueenRookPawn = true;
          } else {
            hasBlackQueenRookPawn = true;
          }
        } else if (piece is Bishop) {
          if (piece.isWhite) {
            whiteBishops++;
          } else {
            blackBishops++;
          }
        } else if (piece is Knight) {
          if (piece.isWhite) {
            whiteKnights++;
          } else {
            blackKnights++;
          }
        }

        // Early return if material is sufficient
        if (hasWhiteQueenRookPawn || hasBlackQueenRookPawn) return false;
        if (whiteBishops > 1 || blackBishops > 1) return false;
        if (whiteKnights > 1 || blackKnights > 1) return false;
        if (whiteBishops > 0 && whiteKnights > 0) return false;
        if (blackBishops > 0 && blackKnights > 0) return false;
      }
    }

    // Only kings, or kings with one minor piece each at most
    return true;
  }
}
